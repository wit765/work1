import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class ProofOfWork {

    public static void main(String[] args) {
        String wit = "Hello, Blockchain!";

        // 寻找4个0开头的哈希
        findHashWithLeadingZeros(wit, 4);

        // 寻找5个0开头的哈希
        findHashWithLeadingZeros(wit, 5);
    }

    public static void findHashWithLeadingZeros(String wit, int leadingZeros) {
        long startTime = System.currentTimeMillis();
        long nonce = 0;
        String targetPrefix = new String(new char[leadingZeros]).replace('\0', '0');
        String hash = "";

        System.out.println("开始寻找" + leadingZeros + "个0开头的哈希...");

        while (true) {
            String input = wit + nonce;
            hash = calculateSHA256(input);

            if (hash.startsWith(targetPrefix)) {
                long endTime = System.currentTimeMillis();
                long duration = endTime - startTime;

                System.out.println("找到符合条件的哈希!");
                System.out.println("花费时间: " + duration + " 毫秒");
                System.out.println("输入内容: " + input);
                System.out.println("哈希值: " + hash);
                System.out.println("Nonce值: " + nonce);
                System.out.println("----------------------------------");
                break;
            }

            nonce++;
        }
    }

    public static String calculateSHA256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(input.getBytes());

            // 将字节数组转换为十六进制字符串
            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }

            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}