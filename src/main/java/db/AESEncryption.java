package db;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;
import java.security.SecureRandom;

/**
 * AES Encryption and Decryption Utility
 * Uses AES-256 for secure password encryption
 * Java 21 Compatible
 */
public class AESEncryption {

    // AES Key Size: 256 bits (32 bytes) for AES-256
    private static final int KEY_SIZE = 256;
    
    // Encryption Algorithm
    private static final String ALGORITHM = "AES";
    
    // Your secret key - CHANGE THIS TO A SECURE KEY!
    // Generate a strong key and keep it safe
    private static final String SECRET_KEY = "MySecretKey12345MySecretKey12345"; // 32 characters for 256-bit key
    
    /**
     * Encrypts a password using AES-256
     * @param password The plain text password
     * @return Base64 encoded encrypted password
     * @throws Exception if encryption fails
     */
    public static String encrypt(String password) throws Exception {
        SecretKey secretKey = getSecretKey();
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(Cipher.ENCRYPT_MODE, secretKey);
        byte[] encryptedPassword = cipher.doFinal(password.getBytes());
        return Base64.getEncoder().encodeToString(encryptedPassword);
    }
    
    /**
     * Decrypts an encrypted password using AES-256
     * @param encryptedPassword The Base64 encoded encrypted password
     * @return Plain text password
     * @throws Exception if decryption fails
     */
    public static String decrypt(String encryptedPassword) throws Exception {
        SecretKey secretKey = getSecretKey();
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(Cipher.DECRYPT_MODE, secretKey);
        byte[] decodedPassword = Base64.getDecoder().decode(encryptedPassword);
        byte[] decryptedPassword = cipher.doFinal(decodedPassword);
        return new String(decryptedPassword);
    }
    
    /**
     * Gets the SecretKey from the stored key string
     * @return SecretKey object for AES operations
     */
    private static SecretKey getSecretKey() {
        // Convert the secret key string to bytes (32 bytes for AES-256)
        byte[] decodedKey = SECRET_KEY.getBytes();
        // Ensure the key is exactly 32 bytes (256 bits)
        byte[] keyBytes = new byte[32];
        System.arraycopy(decodedKey, 0, keyBytes, 0, Math.min(decodedKey.length, 32));
        return new SecretKeySpec(keyBytes, 0, keyBytes.length, ALGORITHM);
    }
    
    /**
     * Generates a random secure key (for initial setup)
     * @return A randomly generated AES-256 key as Base64 string
     * @throws Exception if key generation fails
     */
    public static String generateRandomKey() throws Exception {
        KeyGenerator keyGenerator = KeyGenerator.getInstance(ALGORITHM);
        keyGenerator.init(KEY_SIZE, new SecureRandom());
        SecretKey secretKey = keyGenerator.generateKey();
        return Base64.getEncoder().encodeToString(secretKey.getEncoded());
    }
    
    /**
     * Test method to verify encryption and decryption
     */
    public static void main(String[] args) {
        try {
            String plainPassword = "myPassword123";
            
            System.out.println("Original Password: " + plainPassword);
            
            // Encrypt
            String encrypted = encrypt(plainPassword);
            System.out.println("Encrypted Password: " + encrypted);
            
            // Decrypt
            String decrypted = decrypt(encrypted);
            System.out.println("Decrypted Password: " + decrypted);
            
            // Verify
            if (plainPassword.equals(decrypted)) {
                System.out.println("✓ Encryption and Decryption successful!");
            } else {
                System.out.println("✗ Encryption and Decryption failed!");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}