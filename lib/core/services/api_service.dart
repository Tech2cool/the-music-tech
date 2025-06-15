import 'package:dio/dio.dart';
import 'package:the_music_tech/core/models/app_update.dart';
import 'package:the_music_tech/core/models/models/home_suggestion.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';

// const baseUrl = "https://music-tech-rho.vercel.app";
// const baseUrl = "http://192.168.1.109:8082";
// const baseUrl = "http://129.154.251.173";

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final List<String> _baseUrls = [
    "http://129.154.251.173", // Backup
    "https://music-tech-rho.vercel.app", // Primary
    // "http://192.168.1.109:8082", // Primary
  ];
  late String baseUrl;

  ApiService._internal() {
    _dio = Dio();
  }

  Future<void> initialize() async {
    for (String url in _baseUrls) {
      try {
        final response = await _dio.get(url,
            options: Options(
              receiveTimeout: Duration(seconds: 2),
              sendTimeout: Duration(seconds: 2),
              validateStatus: (status) => status! < 500,
            ));
        if (response.statusCode == 200) {
          baseUrl = url;
          _dio.options.baseUrl = baseUrl;
          // print("✅ Connected to: $baseUrl");
          return;
        }
      } catch (_) {
        // print("❌ Failed to connect to $url");
      }
    }

    throw Exception("🚫 No valid baseUrl could be reached.");
  }

  Dio get client => _dio;

  Future<List<HomeSuggestion>> getHomeData() async {
    try {
      var url = '/home';
      // print('pass url');
      final Response response = await _dio.get(url);
      // print('pass resp');
      final List<dynamic> data = response.data['data'];
      // print('pass list data');
      final dataList = data.map((ele) => HomeSuggestion.fromMap(ele)).toList();
      // print('pass parsing data');
      return dataList;
    } catch (e) {
      // print(e);
      return [];
    }
  }

  Future<List<SearchModel>> searchSongs(
    String query, [
    String type = 'ALL',
  ]) async {
    try {
      // print('entered');
      var url = '/search/$type?query=$query';
      // print('passed url');
      final Response response = await _dio.get(url);
      // print('passed response');
      final List<dynamic> data = response.data['data'];
      // print('passed data');
      final dataList = data.map((ele) => SearchModel.fromMap(ele)).toList();
      // print('passed parsing');
      return dataList;
    } catch (e, stackTrace) {
      // print(e);
      // print(stackTrace);
      return [];
    }
  }

  Future<List<SearchModel>> getPlayListById(String id) async {
    try {
      var url = '/playlist/$id';
      final Response response = await _dio.get(url);
      final List<dynamic> data = response.data['data'];
      final dataList = data.map((ele) => SearchModel.fromMap(ele)).toList();
      return dataList;
    } catch (e) {
      return [];
    }
  }

  Future<SearchModel?> getArtistById(String artistId) async {
    try {
      var url = '/artist/$artistId';
      final Response response = await _dio.get(url);
      final data = response.data['data'];
      return SearchModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<SearchModel?> getAlbumById(String albumId) async {
    try {
      var url = '/album/$albumId';
      final Response response = await _dio.get(url);
      final data = response.data['data'];
      return SearchModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<AppUpdate?> checkAppUpdate() async {
    try {
      // print('pass 1');
      final Response response = await _dio.get('/version');
      // print('pass 2');

      final data = response.data["data"];
      // print('pass 3');
      // print(data);
      final AppUpdate update = AppUpdate.fromMap(data);
      // print('pass 4');

      return update;
    } on DioException catch (e) {
      // print('$e');
      String errorMessage = 'Something went wrong';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else {
        errorMessage = e.message?.toString() ?? errorMessage;
      }

      // Prevent literal 'null' from showing
      if (errorMessage.trim().toLowerCase() == 'null') {
        errorMessage = 'Something went wrong';
      }
      // Helper.showCustomSnackBar(errorMessage);
      return null;
    }
  }
}
