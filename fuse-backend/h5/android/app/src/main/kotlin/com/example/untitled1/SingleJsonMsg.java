package com.example.untitled1;

import android.os.Parcel;
import android.text.TextUtils;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.rong.common.ParcelUtils;
import io.rong.imlib.MessageTag;
import io.rong.imlib.model.MessageContent;

@MessageTag(value = "LC:SingleJsonMsg", flag = MessageTag.ISCOUNTED)
public class SingleJsonMsg extends MessageContent {
    private static final String TAG = "SingleJsonMsg";/*hardcode_shuffle*/

    private final String CONTENT = "content";/*hardcode_shuffle*/
    private final String CONTENT_TYPE = "contentType";/*hardcode_shuffle*/
    private final String EXTRA = "extra";/*hardcode_shuffle*/

    private String content;
    private String contentType;
    private String extra;

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getContent() {
        return content;
    }

    public String getExtra() {
        return extra;
    }

    public void setExtra(String extra) {
        this.extra = extra;
    }

    public byte[] encode() {
        JSONObject jsonObj = new JSONObject();

        try {
            if (!TextUtils.isEmpty(this.getContent()))
                jsonObj.put(CONTENT, this.getContent());

            if (!TextUtils.isEmpty(this.getContentType()))
                jsonObj.put(CONTENT_TYPE, this.getContentType());

            if (!TextUtils.isEmpty(this.getExtra()))
                jsonObj.put(EXTRA, this.getExtra());
        } catch (JSONException ignored) {
        }
        return jsonObj.toString().getBytes(StandardCharsets.UTF_8);
    }

    protected SingleJsonMsg() {
    }

    public static SingleJsonMsg obtain(String content, String contentType, String fromUserId, String toUserId, String extra) {
        SingleJsonMsg model = new SingleJsonMsg();
        model.setContent(content);
        model.setContentType(contentType);
        model.setExtra(extra);
        return model;
    }

    public SingleJsonMsg(byte[] data) {
        if (data == null) {
            Log.e(TAG, "data empty");
            return;
        }

        String jsonStr = new String(data, StandardCharsets.UTF_8);

        try {
            JSONObject jsonObj = new JSONObject(jsonStr);

            if (jsonObj.has(CONTENT))
                this.setContent(jsonObj.optString(CONTENT));

            if (jsonObj.has(CONTENT_TYPE))
                this.setContentType(jsonObj.optString(CONTENT_TYPE));

            if (jsonObj.has(EXTRA))
                this.setExtra(jsonObj.optString(EXTRA));
        } catch (JSONException ignored) {
        }
    }

    public SingleJsonMsg(Parcel in) {
        this.setContent(ParcelUtils.readFromParcel(in));
        this.setContentType(ParcelUtils.readFromParcel(in));
        this.setExtra(ParcelUtils.readFromParcel(in));
    }

    public SingleJsonMsg(String content) {
        this.setContent(content);
    }

    public int describeContents() {
        return 0;
    }

    public void writeToParcel(Parcel dest, int flags) {
        ParcelUtils.writeToParcel(dest, this.content);
        ParcelUtils.writeToParcel(dest, this.contentType);
        ParcelUtils.writeToParcel(dest, this.extra);
    }

    private String getEmotion(String content) {
        Pattern pattern = Pattern.compile("\\[/u([0-9A-Fa-f]+)\\]");
        Matcher matcher = pattern.matcher(content);

        StringBuffer sb;
        int inthex;
        for (sb = new StringBuffer(); matcher.find(); matcher.appendReplacement(sb, String.valueOf(Character.toChars(inthex)))) {
            String matchStr = matcher.group(1);
            inthex = 0;
            if (matchStr != null) {
                inthex = Integer.parseInt(matchStr, 16);
            }
        }

        matcher.appendTail(sb);
        return sb.toString();
    }

    public List<String> getSearchableWord() {
        List<String> words = new ArrayList<>();
        words.add(this.content);
        return words;
    }

    public static final Creator<SingleJsonMsg> CREATOR = new Creator<SingleJsonMsg>() {
        public SingleJsonMsg createFromParcel(Parcel source) {
            return new SingleJsonMsg(source);
        }

        public SingleJsonMsg[] newArray(int size) {
            return new SingleJsonMsg[size];
        }
    };
}