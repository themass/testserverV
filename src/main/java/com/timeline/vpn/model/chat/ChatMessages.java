// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
// Code generated by Microsoft (R) TypeSpec Code Generator.
package com.timeline.vpn.model.chat;

import com.azure.ai.openai.models.ChatRequestMessage;
import com.azure.core.annotation.Fluent;
import com.azure.core.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.Map;

@Fluent
public final class ChatMessages {

    @Generated
    @JsonProperty(value = "messages")
    private List<ChatMsg> messages;

    /*
     * The maximum number of tokens to generate.
     */
    @Generated
    @JsonProperty(value = "max_tokens")
    private Integer maxTokens;

    @Generated
    @JsonProperty(value = "temperature")
    private Double temperature;

    @Generated
    @JsonProperty(value = "top_p")
    private Double topP;

    @Generated
    @JsonProperty(value = "logit_bias")
    private Map<String, Integer> logitBias;

    @Generated
    @JsonProperty(value = "user")
    private String user;

    @Generated
    @JsonProperty(value = "n")
    private Integer n;

    @Generated
    @JsonProperty(value = "stop")
    private List<String> stop;

    @Generated
    @JsonProperty(value = "presence_penalty")
    private Double presencePenalty;

    @Generated
    @JsonProperty(value = "frequency_penalty")
    private Double frequencyPenalty;

    @Generated
    @JsonProperty(value = "stream")
    private Boolean stream;

    @Generated
    @JsonProperty(value = "model")
    private String model;

    public List<ChatMsg> getMessages() {
        return messages;
    }

    public void setMessages(List<ChatMsg> messages) {
        this.messages = messages;
    }

    public Integer getMaxTokens() {
        return maxTokens;
    }

    public void setMaxTokens(Integer maxTokens) {
        this.maxTokens = maxTokens;
    }

    public Double getTemperature() {
        return temperature;
    }

    public void setTemperature(Double temperature) {
        this.temperature = temperature;
    }

    public Double getTopP() {
        return topP;
    }

    public void setTopP(Double topP) {
        this.topP = topP;
    }

    public Map<String, Integer> getLogitBias() {
        return logitBias;
    }

    public void setLogitBias(Map<String, Integer> logitBias) {
        this.logitBias = logitBias;
    }

    public String getUser() {
        return user;
    }

    public void setUser(String user) {
        this.user = user;
    }

    public Integer getN() {
        return n;
    }

    public void setN(Integer n) {
        this.n = n;
    }

    public List<String> getStop() {
        return stop;
    }

    public void setStop(List<String> stop) {
        this.stop = stop;
    }

    public Double getPresencePenalty() {
        return presencePenalty;
    }

    public void setPresencePenalty(Double presencePenalty) {
        this.presencePenalty = presencePenalty;
    }

    public Double getFrequencyPenalty() {
        return frequencyPenalty;
    }

    public void setFrequencyPenalty(Double frequencyPenalty) {
        this.frequencyPenalty = frequencyPenalty;
    }

    public Boolean getStream() {
        return stream;
    }

    public void setStream(Boolean stream) {
        this.stream = stream;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }
}
