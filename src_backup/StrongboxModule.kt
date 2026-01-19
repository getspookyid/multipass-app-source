package io.getspooky.multipass

import android.content.pm.PackageManager
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.spec.ECGenParameterSpec

class StrongboxModule(private val packageManager: PackageManager) {
    private val TAG = "StrongboxModule"
    private val KEYSTORE_PROVIDER = "AndroidKeyStore"

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateKey" -> {
                val alias = call.argument<String>("alias") ?: "spooky_identity"
                generateKey(alias, result)
            }
            "getAttestation" -> {
                val alias = call.argument<String>("alias") ?: "spooky_identity"
                getAttestation(alias, result)
            }
            "isStrongBoxAvailable" -> {
                result.success(hasStrongBox())
            }
            else -> result.notImplemented()
        }
    }

    private fun hasStrongBox(): Boolean {
        // In UNSAFE_DEV_MODE (Emulator), this will likely return false.
        return packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
    }

    private fun generateKey(alias: String, result: MethodChannel.Result) {
        try {
            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC, KEYSTORE_PROVIDER
            )
            
            // Challenge for attestation (nonce). In production, this comes from the server.
            // For key generation, we can set a dummy challenge or omitted if not needed immediately.
            // However, Android requires a challenge to trigger Attestation Certificate generation.
            val challenge = "SPK_INIT_${System.currentTimeMillis()}".toByteArray()

            val builder = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setAttestationChallenge(challenge)
            
            if (hasStrongBox()) {
                Log.i(TAG, "Requesting StrongBox Key generation for alias: $alias")
                builder.setIsStrongBoxBacked(true)
            } else {
                Log.w(TAG, "StrongBox unavailable. Falling back to TEE for alias: $alias")
                // SECURITY WARNING is logged
            }

            keyPairGenerator.initialize(builder.build())
            keyPairGenerator.generateKeyPair()
            
            result.success(true)

        } catch (e: Exception) {
            Log.e(TAG, "Key Generation failed", e)
            result.error("KEY_GEN_ERROR", e.message, null)
        }
    }

    private fun getAttestation(alias: String, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            
            val chain = keyStore.getCertificateChain(alias)
            if (chain == null || chain.isEmpty()) {
                result.error("NO_KEY", "Key not found for alias $alias", null)
                return
            }

            // Return chain as List of specific Base64 strings
            val encodedChain = chain.map { cert ->
                Base64.encodeToString(cert.encoded, Base64.NO_WRAP)
            }
            result.success(encodedChain)

        } catch (e: Exception) {
            Log.e(TAG, "Attestation retrieval failed", e)
            result.error("ATTESTATION_ERROR", e.message, null)
        }
    }
}
