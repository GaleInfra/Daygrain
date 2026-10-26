package com.example.untitled1;

import android.content.Context;
import android.os.Bundle;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

import cn.rongcloud.im.wrapper.flutter.RCIMWrapperEngine;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.rong.imlib.model.MessageContent;

public class MainActivity extends FlutterActivity {
    private MethodChannel riskChannel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getRiskChannel().setMethodCallHandler((call, result) -> {
            if (TextUtils.equals("getAutoTimeZone", call.method)) {
                boolean r = isAutoTimeAndZone(getActivity());
                result.success(r);
            } else if (TextUtils.equals("getVirtual", call.method)) {
                boolean r = CheckVirtual.isRunInVirtual();
                result.success(r);
            } else if (TextUtils.equals("getHook", call.method)) {
                boolean r = CheckHook.isHook(getActivity());
                result.success(r);
            } else if (TextUtils.equals("getRoot", call.method)) {
                boolean r = CheckRoot.isDeviceRooted();
                result.success(r);
            } else if (TextUtils.equals("getProxy", call.method)) {
                boolean r = checkProxy();
                result.success(r);
            } else {
                result.error("1", "Illegal Argument Exception",
                        "Unsupported Method - " + call.method);
            }
        });
        List<Class<? extends MessageContent>> list = new ArrayList<>();
        list.add(HyperLinkMsg.class);
        list.add(NoneFlagMsg.class);
        list.add(SingleJsonMsg.class);
        RCIMWrapperEngine.getInstance().messageContentClassList = list;
    }

    private MethodChannel getRiskChannel() {
        if (riskChannel == null) {
            riskChannel = new MethodChannel(getFlutterEngine().getDartExecutor(), "risk_channel");
        }
        return riskChannel;
    }

    // 获取是否自动设置时区
    public boolean isAutoTimeAndZone(Context context) {
        if (context == null) return false;
        boolean isAutoTimeEnabled = false;
        boolean isAutoTimeZoneEnabled = false;
        try {
            // 获取是否自动设置时间
            isAutoTimeEnabled = Settings.Global.getInt(context.getContentResolver(), Settings.Global.AUTO_TIME, 0) != 0;
            // 获取是否自动设置时区
            isAutoTimeZoneEnabled = Settings.Global.getInt(context.getContentResolver(), Settings.Global.AUTO_TIME_ZONE, 0) != 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return isAutoTimeEnabled && isAutoTimeZoneEnabled;
    }

    /**
     * 是否开启了代理
     *
     * @return
     */
    public boolean checkProxy() {
        String proxyAddress = System.getProperty("http.proxyHost");
        int proxyPort = 0;
        String portStr = System.getProperty("http.proxyPort");
        if (!TextUtils.isEmpty(portStr)) {
            proxyPort = Integer.parseInt(portStr);
        }
        Log.d("MainActivity", "checkProxy: " + "地址:" + proxyAddress + " 端口：" + proxyPort);
        return !TextUtils.isEmpty(proxyAddress) && proxyPort != 0;
    }
}
