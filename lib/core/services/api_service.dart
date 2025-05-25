import 'package:dio/dio.dart';
import 'package:the_music_tech/core/models/models/home_suggestion.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';

const baseUrl = "https://music-tech-rho.vercel.app";
// const baseUrl = "http://192.168.1.109:8082";

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
    // _dio.interceptors.add(_A uthInterceptor());
    // _dio.interceptors.add(_ResponseInterceptor());
  }

  Future<List<HomeSuggestion>> getHomeData() async {
    try {
      var url = '/home';
      print('pass url');
      final Response response = await _dio.get(url);
      print('pass resp');
      final List<dynamic> data = response.data['data'];
      print('pass list data');
      final dataList = data.map((ele) => HomeSuggestion.fromMap(ele)).toList();
      print('pass parsing data');
      return dataList;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<SearchModel>> searchSongs(
    String query, [
    String type = 'ALL',
  ]) async {
    try {
      print('entered');
      var url = '/search/$type?query=$query';
      print('passed url');
      final Response response = await _dio.get(url);
      print('passed response');
      final List<dynamic> data = response.data['data'];
      print('passed data');
      final dataList = data.map((ele) => SearchModel.fromMap(ele)).toList();
      print('passed parsing');
      return dataList;
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
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
}
