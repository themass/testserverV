package vpn.test;//package com.timeline.vpn.test;
//
//import com.google.cloud.language.v1.Client;
//import com.google.cloud.language.v1.Document;
//import com.google.cloud.language.v1.GenerateTextRequest;
//import com.google.cloud.language.v1.GenerateTextResponse;
//
//public class Example {
//
//  public static void main(String[] args) throws Exception {
//    // Create a client.
//    Client client = Client.create();
//
//    // Create a document.
//    Document document = Document.newBuilder().setText("今天天气很好。").build();
//
//    // Generate text.
//    GenerateTextRequest request = GenerateTextRequest.newBuilder().setDocument(document).build();
//    GenerateTextResponse response = client.generateText(request);
//
//    // Print the generated text.
//    System.out.println(response.getText());
//  }
//}
