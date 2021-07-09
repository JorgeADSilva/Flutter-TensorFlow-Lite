class Result{
  double confidence;
  int id;
  String label;

  Result(this.confidence, this.id, this.label);

  @override
  String toString() {
  return "Result $id: ->Confidence: $confidence | Label: $label";
   }
}