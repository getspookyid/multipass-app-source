package io.getspooky.multipass

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.nio.charset.StandardCharsets

class ApduService : HostApduService() {
    private val TAG = "ApduService"
    private val MDL_AID = byteArrayOf(
        0xA0.toByte(), 0x00.toByte(), 0x00.toByte(), 0x02.toByte(), 
        0x47.toByte(), 0x10.toByte(), 0x01.toByte()
    )

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) return ByteArray(0)
        
        Log.i(TAG, "Received APDU: ${toHex(commandApdu)}")

        // Check if SELECT command
        if (isSelectCommand(commandApdu)) {
            Log.i(TAG, "ISO 18013-5 AID Selected!")
            
            // Should return NDEF Handover Select message
            // For Phase 2.2 Proof of Concept, we return status OK 9000 
            // The real NDEF blob is large and requires constructing the BLE OOB data.
            // We will stub this for now to prove HCE connectivity.
            return byteArrayOf(0x90.toByte(), 0x00.toByte())
        }

        return byteArrayOf(0x6F.toByte(), 0x00.toByte()) // Status: Error/Unknown
    }

    override fun onDeactivated(reason: Int) {
        Log.i(TAG, "Deactivated: $reason")
    }

    private fun isSelectCommand(apdu: ByteArray): Boolean {
        // SELECT (00 A4 04 00)
        return apdu.size >= 4 && 
               apdu[0] == 0x00.toByte() && 
               apdu[1] == 0xA4.toByte() && 
               apdu[2] == 0x04.toByte() && 
               apdu[3] == 0x00.toByte()
    }

    private fun toHex(bytes: ByteArray): String {
        val sb = StringBuilder()
        for (b in bytes) {
            sb.append(String.format("%02X", b))
        }
        return sb.toString()
    }
}
