abstract class ProfileTransport {
  String get label;
}

class FileProfileTransport implements ProfileTransport {
  const FileProfileTransport();

  @override
  String get label => 'File';
}
