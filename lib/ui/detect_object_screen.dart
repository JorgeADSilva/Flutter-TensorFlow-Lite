import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_recognition/helper/camera_helper.dart';
import 'package:image_recognition/helper/tensor_flow_lite_helper.dart';
import 'package:image_recognition/model/result.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DetectObjectScreen extends StatefulWidget {
  const DetectObjectScreen ({ Key key }) : super(key: key);

  @override
  _DetectObjectScreenState createState() => _DetectObjectScreenState();
}

class _DetectObjectScreenState extends State<DetectObjectScreen> with TickerProviderStateMixin{
  AnimationController _colorAnimationController;
  Animation _colorTween;

  List<Result> outputs;

  @override
  void initState() { 
    super.initState();
    
    //TODO: ADD MODEL PATH HERE
    TenserFlowLiteHelper.loadModel().then((value){
      setState(() {
        TenserFlowLiteHelper.lodadedModel = true;
      });
    });

    CameraHelper.initializeCamera();

    _setupAnimation();

    //Subscribe to Tensor Flow Lite's Classify Events

    TenserFlowLiteHelper.tfLiteResultsController.stream.listen((results) {
      results.forEach((result) {
        _colorAnimationController.animateTo(result.confidence, curve: Curves.bounceIn, duration: Duration(seconds: 3));
      });

      outputs = results;

      //Update results on the screen
      setState(() {
        CameraHelper.isDetecting = false;        
      });
    }, onDone: (){},
    onError: (error){
      print("****** Listener error ${error.toString()}");
    });
  }

  void _setupAnimation(){
    _colorAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 3));
    _colorTween = ColorTween(begin: Colors.green, end: Colors.red).animate(_colorAnimationController);
  }

  @override
  void dispose() { 
    TenserFlowLiteHelper.disposeModel();
    CameraHelper.cameraController.dispose();
    print("****** Dispose method called");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Detecting objects"),
      ),
      body: FutureBuilder<void>(
        future: CameraHelper.initializeControllerFuture,
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.done){
            return Stack(
              children: <Widget>[
                CameraPreview(CameraHelper.cameraController),
                _buildResultsSection(width, outputs)
              ],
            );
          }else{
            return Center(child: CircularProgressIndicator());
          }
        },),
    );
  }

  Widget _buildResultsSection(double width, List<Result> outputs) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 200.0,
          width: width,
          color: Colors.white,
          child: outputs != null && outputs.isNotEmpty
              ? ListView.builder(
                  itemCount: outputs.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        Text(
                          outputs[index].label,
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 20.0,
                          ),
                        ),
                        AnimatedBuilder(
                            animation: _colorAnimationController,
                            builder: (context, child) => LinearPercentIndicator(
                                  width: width * 0.88,
                                  lineHeight: 14.0,
                                  percent: outputs[index].confidence,
                                  progressColor: _colorTween.value,
                                )),
                        Text(
                          "${(outputs[index].confidence * 100.0).toStringAsFixed(2)} %",
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    );
                  })
              : Center(
                  child: Text("Wating for model to detect..",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                      ))),
        ),
      ),
    );
  }
}