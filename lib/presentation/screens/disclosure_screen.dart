import 'package:flutter/material.dart';
import 'package:multipass/data/repositories/credential_repository.dart';
import 'package:provider/provider.dart';

class DisclosureScreen extends StatefulWidget {
  final String verifierName;
  final String nonce;

  const DisclosureScreen(
      {super.key, required this.verifierName, required this.nonce});

  @override
  _DisclosureScreenState createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends State<DisclosureScreen> {
  // Mock attributes matching Repository
  final List<String> _labels = [
    "Credential ID",
    "DID",
    "Family Name",
    "Given Name",
    "Birth Date",
    "Issue Date",
    "Expiry Date",
    "Privileges"
  ];

  // Track selected indices
  final Set<int> _selectedIndices = {};
  String _statusMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Share with ${widget.verifierName}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select attributes to disclose. Unchecked fields remain cryptographically hidden.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(_labels[index]),
                  value: _selectedIndices.contains(index),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIndices.add(index);
                      } else {
                        _selectedIndices.remove(index);
                      }
                    });
                  },
                );
              },
            ),
          ),
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_statusMessage,
                  style: const TextStyle(color: Colors.green)),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: _generateProof,
              child: const Text("GENERATE PROOF"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateProof() async {
    setState(() => _statusMessage = "Generating Zero-Knowledge Proof...");

    try {
      final repo = Provider.of<CredentialRepository>(context, listen: false);
      final proof = await repo.generatePresentation(
        revealedIndices: _selectedIndices.toList(),
        nonce: widget.nonce,
        siteId: "site_abc", // Derived from Verifier info in real app
      );

      setState(
          () => _statusMessage = "Success! Proof Size: ${proof.length} bytes");

      // In a real flow, we would now POST this proof to the Verifier or send it via BLE
    } catch (e) {
      setState(() => _statusMessage = "Error: $e");
    }
  }
}
