
import 'package:flutter/material.dart';

import 'package:gl_canvas/gl_canvas.dart';

import 'factory_stub.dart'
if (dart.library.io) 'renderer_io.dart'
if (dart.library.html) 'renderer_web.dart';

void main() {
  runApp(MyApp());
}

abstract class CanvasRenderer {
  void render();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late GLCanvasController controller;
  late CanvasRenderer renderer;

  @override
  void initState() {
    super.initState();

    controller = GLCanvasController();
    renderer = createRenderer(512, 512, controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(controller, renderer),
    );
  }
}

class Home extends StatelessWidget {
  final GLCanvasController controller;
  final CanvasRenderer renderer;

  Home(this.controller, this.renderer);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                  onPressed: () {
                    controller.beginDraw();
                    renderer.render();
                    controller.endDraw();
                  },
                  child: Text("Draw")
              ),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text("Hello"),
                        ),
                      );
                    }));
                  },
                  child: Text("Push")
              ),
            ],
          ),
          Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.blue,
                  child: GLCanvas(
                    controller: controller,
                  ),
                ),
              )
          )
        ],
      ),
    );
  }
}
