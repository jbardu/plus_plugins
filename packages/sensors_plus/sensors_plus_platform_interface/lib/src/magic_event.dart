/// A sensor sample from a magic.
///
class MagicEvent {
  MagicEvent(this.m11, this.m12, this.m13,
	     this.m21, this.m22, this.m23,
	     this.m31, this.m32, this.m33);

  final double m11, m12, m13,
		m21, m22, m23, 
		m31, m32, m33;

  @override
  String toString() => '[MagicEvent ($m11, $m12, $m13, $m21  $m22, $m23, $m31, $m32  $m33)]';
}
