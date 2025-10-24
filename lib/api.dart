class Api {
  static const String baseUrl = 'https://techman-api-2025.vercel.app/';
  static getEndPoint(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
