package com.ero.gl_canvas;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.TextureRegistry;

/** GlCanvasPlugin */
public class GLCanvasPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private TextureRegistry textureRegistry;

  private Map<Long, GLTexture> textureMap = new HashMap<>();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "gl_canvas");
    channel.setMethodCallHandler(this);

    textureRegistry = flutterPluginBinding.getTextureRegistry();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("init")) {
      int width = ((Number)call.argument("width")).intValue();
      int height = ((Number)call.argument("height")).intValue();
      int version = ((Number)call.argument("version")).intValue();
      GLTexture texture = new GLTexture(textureRegistry, width, height, version);
      textureMap.put(texture.getTextureId(), texture);
      result.success(texture.getTextureId());
    } else if (call.method.equals("destroy")) {
      Number id = (Number)call.argument("id");
      GLTexture texture = textureMap.get(id.longValue());
      if (texture != null) {
        texture.destroy();
      }
      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
