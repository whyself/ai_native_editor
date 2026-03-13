import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex_example/tex_view_document_example.dart';
import 'package:flutter_tex_example/tex_view_fonts_example.dart';
import 'package:flutter_tex_example/tex_view_image_video_example.dart';
import 'package:flutter_tex_example/tex_view_ink_well_example.dart';
import 'package:flutter_tex_example/tex_view_markdown_example.dart';
import 'package:flutter_tex_example/tex_view_quiz_example.dart';

main() async {
  if (!kIsWeb) {
    await TeXRenderingServer.start();
  }
  runApp(const FlutterTeXExample());
}

class FlutterTeXExample extends StatelessWidget {
  const FlutterTeXExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TeXViewFullExample(),
    );
  }
}

class TeXViewFullExample extends StatefulWidget {
  const TeXViewFullExample({super.key});

  @override
  State<TeXViewFullExample> createState() => _TeXViewFullExampleState();
}

class _TeXViewFullExampleState extends State<TeXViewFullExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Flutter TeX (Demo)"),
      ),
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              "assets/flutter_tex_banner.png",
              fit: BoxFit.contain,
              height: 200,
            ),
          ),
          const Divider(
            height: 30,
            color: Colors.transparent,
          ),
          getExampleButton(context, 'Quiz Example', const TeXViewQuizExample()),
          getExampleButton(
              context, 'TeX Examples', const TeXViewDocumentExamples()),
          getExampleButton(
              context, 'Markdown Examples', const TeXViewMarkdownExamples()),
          getExampleButton(
              context, 'Custom Fonts Examples', const TeXViewFontsExamples()),
          getExampleButton(context, 'Image & Video Example',
              const TeXViewImageVideoExample()),
          getExampleButton(
              context, 'Inkwell Example', const TeXViewInkWellExample()),
        ],
      ),
    );
  }

  getExampleButton(BuildContext context, String title, Widget widget) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        style: ButtonStyle(
            elevation: WidgetStateProperty.all(5),
            backgroundColor: WidgetStateProperty.all(Colors.white)),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => widget));
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
