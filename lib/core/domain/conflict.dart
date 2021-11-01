class Conflict<T> {
  Conflict(this.mine, this.their, this.type);
  final T mine;
  final T their;
  final String type;
}
