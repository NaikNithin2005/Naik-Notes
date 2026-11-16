/// Application route path constants.
class RouteNames {
  RouteNames._();

  static const String dashboard = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String phoneAuth = '/phone-auth';
  static const String notebookView = '/notebook/:id';
  static const String templateGallery = '/templates';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String pdfEditor = '/pdf';
  static const String audioNotes = '/audio';
  static const String aiAssistant = '/ai';

  static String notebookPath(String id) => '/notebook/$id';
}
