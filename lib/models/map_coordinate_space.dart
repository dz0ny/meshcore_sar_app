enum MapCoordinateSpace {
  geo,
  customMap;

  static MapCoordinateSpace fromName(String? value) {
    return MapCoordinateSpace.values.firstWhere(
      (space) => space.name == value,
      orElse: () => MapCoordinateSpace.geo,
    );
  }
}
