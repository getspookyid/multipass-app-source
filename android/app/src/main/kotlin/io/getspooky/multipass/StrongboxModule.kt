package io.getspooky.multipass

import android.content.pm.PackageManager
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
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
            "sign" -> {
                val alias = call.argument<String>("alias") ?: "spooky_identity"
                val data = call.argument<ByteArray>("data")
                if (data == null) {
                    result.error("INVALID_ARGUMENT", "Data is required", null)
                } else {
                    sign(alias, data, result)
                }
            }
            "generateSymKey" -> {
                val alias = call.argument<String>("alias") ?: "spooky_sym_key"
                generateSymKey(alias, result)
            }
            "encryptSym" -> {
                val alias = call.argument<String>("alias") ?: "spooky_sym_key"
                val data = call.argument<String>("data") // Expecting UTF-8 string
                if (data == null) {
                    result.error("INVALID_ARGUMENT", "Data is required", null)
                } else {
                    encryptSym(alias, data, result)
                }
            }
            "decryptSym" -> {
                val alias = call.argument<String>("alias") ?: "spooky_sym_key"
                val encryptedData = call.argument<String>("encryptedData") // Base64
                val iv = call.argument<String>("iv") // Base64
                if (encryptedData == null || iv == null) {
                    result.error("INVALID_ARGUMENT", "Encrypted data and IV are required", null)
                } else {
                    decryptSym(alias, encryptedData, iv, result)
                }
            }
            "checkAttestation" -> {
                val alias = call.argument<String>("alias") ?: "spooky_identity"
                checkAttestation(alias, result)
            }
            "getEntropy" -> {
                val size = call.argument<Int>("size") ?: 32
                result.success(getEntropy(size))
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

    private fun sign(alias: String, data: ByteArray, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            
            val entry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            if (entry == null) {
                result.error("NO_KEY", "Key not found for alias $alias", null)
                return
            }

            val signer = java.security.Signature.getInstance("SHA256withECDSA")
            signer.initSign(entry.privateKey)
            signer.update(data)
            val signature = signer.sign()
            
            result.success(signature)

        } catch (e: Exception) {
            Log.e(TAG, "Signing failed", e)
            result.error("SIGN_ERROR", e.message, null)
        }
    }

    private fun generateSymKey(alias: String, result: MethodChannel.Result) {
        try {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER
            )
            
            val builder = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            
            if (hasStrongBox()) {
                Log.i(TAG, "Requesting StrongBox AES Key generation for alias: $alias")
                builder.setIsStrongBoxBacked(true)
            } else {
                Log.w(TAG, "StrongBox unavailable. Falling back to TEE for alias: $alias")
            }

            keyGenerator.init(builder.build())
            keyGenerator.generateKey()
            
            result.success(true)

        } catch (e: Exception) {
            Log.e(TAG, "Symmetric Key Generation failed", e)
            result.error("KEY_GEN_ERROR", e.message, null)
        }
    }

    private fun encryptSym(alias: String, data: String, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            
            val secretKeyEntry = keyStore.getEntry(alias, null) as? KeyStore.SecretKeyEntry
            if (secretKeyEntry == null) {
                 // Auto-generate if missing
                 Log.i(TAG, "Key not found, auto-generating...")
                 val genResult = object : MethodChannel.Result {
                     override fun success(res: Any?) {
                         // Recursive call after generation
                         encryptSym(alias, data, result) 
                     }
                     override fun error(code: String, msg: String?, details: Any?) {
                         result.error(code, msg, details)
                     }
                     override fun notImplemented() { result.notImplemented() }
                 }
                 generateSymKey(alias, genResult)
                 return
            }
            
            val secretKey = secretKeyEntry.secretKey
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            
            val iv = cipher.iv
            val cipherText = cipher.doFinal(data.toByteArray(Charsets.UTF_8))
            
            val resultMap = mapOf(
                "encryptedData" to Base64.encodeToString(cipherText, Base64.NO_WRAP),
                "iv" to Base64.encodeToString(iv, Base64.NO_WRAP)
            )
            
            result.success(resultMap)

        } catch (e: Exception) {
            Log.e(TAG, "Encryption failed", e)
            result.error("ENCRYPT_ERROR", e.message, null)
        }
    }

    private fun decryptSym(alias: String, encryptedDataBase64: String, ivBase64: String, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            
            val secretKeyEntry = keyStore.getEntry(alias, null) as? KeyStore.SecretKeyEntry
            if (secretKeyEntry == null) {
                result.error("NO_KEY", "Key not found for alias $alias", null)
                return
            }
            
            val secretKey = secretKeyEntry.secretKey
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, Base64.decode(ivBase64, Base64.NO_WRAP))
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            
            val clearText = cipher.doFinal(Base64.decode(encryptedDataBase64, Base64.NO_WRAP))
            
            result.success(String(clearText, Charsets.UTF_8))

        } catch (e: Exception) {
            Log.e(TAG, "Decryption failed", e)
            result.error("DECRYPT_ERROR", e.message, null)
        }
    }

    private fun checkAttestation(alias: String, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            
            val chain = keyStore.getCertificateChain(alias)
            if (chain == null || chain.isEmpty()) {
                // Fail-Closed: No chain = Untrusted
                result.success(false) 
                return
            }
            
            // 1. Check Root CA
            val root = chain[chain.size - 1] as java.security.cert.X509Certificate
            val issuerDN = root.issuerDN.name
            Log.d(TAG, "Attestation Root Issuer: $issuerDN")
            
            val isGoogleRoot = issuerDN.contains("Google") || issuerDN.contains("Android")
            
            // 2. Check for Attestation Extension (OID: 1.3.6.1.4.1.11129.2.1.17)
            val leaf = chain[0] as java.security.cert.X509Certificate
            val attestationExtension = leaf.getExtensionValue("1.3.6.1.4.1.11129.2.1.17")
            val hasExtension = attestationExtension != null
            
            Log.d(TAG, "Has Attestation Extension: $hasExtension")

            // Strict Policy: Must have Google Root AND Attestation Extension
            // (In a real production app, we would parse the ASN.1 structure to verify security level)
            val isSecure = isGoogleRoot && hasExtension
            
            result.success(isSecure)
            
        } catch (e: Exception) {
            Log.e(TAG, "Attestation check failed", e)
            // Fail-Closed on error
            result.success(false)
        }
    }
    private fun getEntropy(size: Int): ByteArray {
        val random = java.security.SecureRandom()
        val bytes = ByteArray(size)
        random.nextBytes(bytes)
        return bytes
    }
}
