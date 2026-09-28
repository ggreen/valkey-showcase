package showcase.valkey.witness.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

@Service
public class ValkeySlotRouter {

    private static final int TOTAL_SLOTS = 16384;

    @Value("${valkey.witness-slots.lower-bound:2}")
    private int lowerBound;

    @Value("${valkey.witness-slots.upper-bound:16381}")
    private int upperBound;

    /**
     * Checks if the calculated slot falls into the reserved Witness Domain based on application properties.
     */
    public boolean isWitnessSlot(int slot) {
        return slot <= lowerBound || slot >= upperBound;
    }

    /**
     * Generates a slot-safe key. If the original identifier lands on a witness slot,
     * it mutates the string inside the hash tag until it lands on a valid data shard.
     */
    public String generateSafeKey(String baseIdentifier, String suffix) {
        String safeKey = "{" + baseIdentifier + "}" + suffix;
        int slot = getSlot(safeKey);
        int mutationCounter = 0;

        while (isWitnessSlot(slot)) {
            mutationCounter++;
            String mutatedIdentifier = baseIdentifier + "_" + mutationCounter;
            safeKey = "{" + mutatedIdentifier + "}" + suffix;
            slot = getSlot(safeKey);
        }

        return safeKey;
    }

    public int getSlot(String key) {
        int start = key.indexOf('{');
        if (start != -1) {
            int end = key.indexOf('}', start + 1);
            if (end != -1 && end != start + 1) {
                key = key.substring(start + 1, end);
            }
        }
        return crc16(key) % TOTAL_SLOTS;
    }

    private int crc16(String str) {
        int crc = 0x0000;
        byte[] bytes = str.getBytes(StandardCharsets.UTF_8);
        for (byte b : bytes) {
            for (int i = 0; i < 8; i++) {
                boolean bit = ((b >> (7 - i) & 1) == 1);
                boolean c15 = ((crc >> 15 & 1) == 1);
                crc <<= 1;
                if (c15 ^ bit) {
                    crc ^= 0x1021;
                }
            }
        }
        return crc & 0xFFFF;
    }
}
