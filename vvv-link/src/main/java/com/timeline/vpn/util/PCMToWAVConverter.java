package com.timeline.vpn.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public class PCMToWAVConverter {

    /**
     * 将 PCM 音频数据转换为 WAV 格式音频文件
     *
     * @param pcmFilePath  PCM 文件路径
     * @param wavFilePath  输出的 WAV 文件路径
     * @param sampleRate   采样率，例如 44100
     * @param channels     声道数，例如 1（单声道）或 2（立体声）
     * @param bitDepth     位深度，例如 16
     * @throws IOException 如果文件读写出现错误
     */
    public static void pcmToWav(String pcmFilePath, String wavFilePath, int sampleRate, int channels, int bitDepth) throws IOException {
        FileInputStream pcmInputStream = null;
        FileOutputStream wavOutputStream = null;

        try {
            // 打开 PCM 文件输入流
            pcmInputStream = new FileInputStream(new File(pcmFilePath));
            // 打开 WAV 文件输出流
            wavOutputStream = new FileOutputStream(new File(wavFilePath));

            // 计算 PCM 数据长度
            long pcmDataLength = new File(pcmFilePath).length();
            // 计算总文件长度
            long totalLength = pcmDataLength + 36;

            // 写入 WAV 文件头
            writeWavHeader(wavOutputStream, totalLength, pcmDataLength, sampleRate, channels, bitDepth);

            // 写入 PCM 数据
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = pcmInputStream.read(buffer)) != -1) {
                wavOutputStream.write(buffer, 0, bytesRead);
            }
        } finally {
            // 关闭输入输出流
            if (pcmInputStream != null) {
                pcmInputStream.close();
            }
            if (wavOutputStream != null) {
                wavOutputStream.close();
            }
        }
    }

    /**
     * 写入 WAV 文件头
     *
     * @param outputStream 输出流
     * @param totalLength  总文件长度
     * @param pcmDataLength  PCM 数据长度
     * @param sampleRate   采样率
     * @param channels     声道数
     * @param bitDepth     位深度
     * @throws IOException 如果写入文件头时出现错误
     */
    private static void writeWavHeader(FileOutputStream outputStream, long totalLength, long pcmDataLength, int sampleRate, int channels, int bitDepth) throws IOException {
        byte[] header = new byte[44];

        // ChunkID: "RIFF"
        header[0] = 'R';
        header[1] = 'I';
        header[2] = 'F';
        header[3] = 'F';

        // ChunkSize: 总文件长度 - 8
        header[4] = (byte) (totalLength & 0xff);
        header[5] = (byte) ((totalLength >> 8) & 0xff);
        header[6] = (byte) ((totalLength >> 16) & 0xff);
        header[7] = (byte) ((totalLength >> 24) & 0xff);

        // Format: "WAVE"
        header[8] = 'W';
        header[9] = 'A';
        header[10] = 'V';
        header[11] = 'E';

        // Subchunk1ID: "fmt "
        header[12] = 'f';
        header[13] = 'm';
        header[14] = 't';
        header[15] = ' ';

        // Subchunk1Size: 16 for PCM
        header[16] = 16;
        header[17] = 0;
        header[18] = 0;
        header[19] = 0;

        // AudioFormat: 1 for PCM
        header[20] = 1;
        header[21] = 0;

        // NumChannels
        header[22] = (byte) channels;
        header[23] = 0;

        // SampleRate
        header[24] = (byte) (sampleRate & 0xff);
        header[25] = (byte) ((sampleRate >> 8) & 0xff);
        header[26] = (byte) ((sampleRate >> 16) & 0xff);
        header[27] = (byte) ((sampleRate >> 24) & 0xff);

        // ByteRate = SampleRate * NumChannels * BitDepth / 8
        int byteRate = sampleRate * channels * bitDepth / 8;
        header[28] = (byte) (byteRate & 0xff);
        header[29] = (byte) ((byteRate >> 8) & 0xff);
        header[30] = (byte) ((byteRate >> 16) & 0xff);
        header[31] = (byte) ((byteRate >> 24) & 0xff);

        // BlockAlign = NumChannels * BitDepth / 8
        short blockAlign = (short) (channels * bitDepth / 8);
        header[32] = (byte) blockAlign;
        header[33] = (byte) (blockAlign >> 8);

        // BitsPerSample
        header[34] = (byte) bitDepth;
        header[35] = 0;

        // Subchunk2ID: "data"
        header[36] = 'd';
        header[37] = 'a';
        header[38] = 't';
        header[39] = 'a';

        // Subchunk2Size: PCM 数据长度
        header[40] = (byte) (pcmDataLength & 0xff);
        header[41] = (byte) ((pcmDataLength >> 8) & 0xff);
        header[42] = (byte) ((pcmDataLength >> 16) & 0xff);
        header[43] = (byte) ((pcmDataLength >> 24) & 0xff);

        // 写入文件头
        outputStream.write(header, 0, 44);
    }

    public static void main(String[] args) {
        try {
            // 示例参数，根据实际情况修改
            String pcmFilePath = "/Users/liguoqing/Downloads/test/voice_1739288846238.wav";
            String wavFilePath = "output.wav";
            int sampleRate = 24000;
            int channels = 1;
            int bitDepth = 16;

            pcmToWav(pcmFilePath, wavFilePath, sampleRate, channels, bitDepth);
            System.out.println("PCM 转换为 WAV 成功！");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}