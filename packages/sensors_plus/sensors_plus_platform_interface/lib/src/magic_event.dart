/// A sensor sample from a magic.
///
class MagicEvent {
  MagicEvent(this.m00, this.m01, this.m02, this.m03,
	     this.m10, this.m11, this.m12, this.m13,
	     this.m20, this.m21, this.m22, this.m23,
	     this.m30, this.m31, this.m32, this.m33
);

  final double m00, m01, m02, m03,
		m10, m11, m12, m13,
		m20, m21, m22, m23,
		m30, m31, m32, m33;

  @override
  String toString() => '[MagicEvent ($m00, $m01, $m02  $m10, $m11, $m12, $m13  $m20, $m21, $m22, $m23  $m30, $m31, $m32, $m33)]';
}
