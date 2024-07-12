package com.timeline.vpn.test;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import java.time.Duration;

public class CloudflareBypass {
    public static void main(String[] args) {
        // 设置ChromeDriver的路径（确保已经下载并解压了ChromeDriver）
//        System.setProperty("webdriver.chrome.driver", "/path/to/chromedriver");
        // 初始化WebDriver
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--ignore-certificate-errors"); // 忽略证书错误
        WebDriver driver = new ChromeDriver(options);
        try {
            // 访问网页
            driver.get("https://hsex.men/video-983657.htm");
            // 等待页面元素加载（根据实际情况选择合适的选择器和等待条件）
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
            WebElement element = wait.until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector("input[type='checkbox'][role='checkbox']")));
            // 获取网页的源代码或其他信息
            String pageSource = driver.getPageSource();
            // TODO: 处理网页内容...
            System.out.println("网页内容获取成功：" + pageSource);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            // 关闭WebDriver
            if (driver != null) {
                driver.quit();
            }
        }
    }
}