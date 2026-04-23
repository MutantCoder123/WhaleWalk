import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.106:8000/api/v1';

  // ---------------------------------------------------------------------------
  // Token Management
  // ---------------------------------------------------------------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
  }

  // ---------------------------------------------------------------------------
  // HTTP Helpers
  // ---------------------------------------------------------------------------
  dynamic _decodeResponse(http.Response response, String label) {
    final contentType = response.headers['content-type'] ?? '';
    final bodyPreview = response.body.length > 180
        ? '${response.body.substring(0, 180)}...'
        : response.body;

    if (!contentType.contains('application/json')) {
      throw Exception(
        '$label returned non-JSON (${response.statusCode}, $contentType): $bodyPreview',
      );
    }

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(
      decoded['message'] ?? '$label failed: ${response.statusCode}',
    );
  }

  Future<dynamic> get(String endpoint) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _decodeResponse(response, 'GET $endpoint');
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _decodeResponse(response, 'POST $endpoint');
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await post('/users/login', {'email': email, 'password': password});
    final token = res['data']['accessToken'];
    final username = res['data']['user']['username'];
    await _saveToken(token);
    await _saveUsername(username);
    return res['data'];
  }

  Future<Map<String, dynamic>> register(String fullName, String email, String username, String password) async {
    final res = await post('/users/register', {
      'fullName': fullName,
      'email': email,
      'username': username,
      'password': password,
    });
    return res['data'];
  }

  Future<void> logout() async {
    try { await post('/users/logout', {}); } catch (_) {}
    await clearToken();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final res = await get('/users/current-user');
    return res['data'];
  }

  // ---------------------------------------------------------------------------
  // Stocks
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> fetchStocks() async {
    final res = await get('/stocks/');
    return res['data'] ?? [];
  }

  Future<Map<String, dynamic>> createStock({
    required String stockId,
    required String name,
    required double price,
    double? previousPrice,
  }) async {
    final res = await post('/stocks/createstock', {
      'stockId': stockId,
      'name': name,
      'price': price,
      if (previousPrice != null) 'previousPrice': previousPrice,
      'history': [previousPrice ?? price, price],
    });
    return res['data'];
  }

  Future<Map<String, dynamic>> placeOrder({
    required String stockId,
    required int quantity,
    required String type,  // 'buy' | 'sell'
    double? limitPrice,    // null = market order
  }) async {
    final body = <String, dynamic>{
      'stockId': stockId,
      'quantity': quantity,
      'type': type,
      'orderType': limitPrice == null ? 'market' : 'limit',
    };
    if (limitPrice != null) body['limitPrice'] = limitPrice;
    final res = await post('/stocks/order', body);
    return res['data'];
  }

  Future<List<dynamic>> getPortfolio() async {
    final res = await get('/stocks/portfolio');
    return res['data'] ?? [];
  }

  Future<List<dynamic>> getMyOrders() async {
    final res = await get('/stocks/orders');
    return res['data'] ?? [];
  }

  Future<List<dynamic>> getCompletedOrders() async {
    final res = await get('/stocks/completed-orders');
    return res['data'] ?? [];
  }

  // ---------------------------------------------------------------------------
  // Wallet
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchWallet() async {
    final res = await get('/users/wallet');
    return res['data'];
  }

  Future<Map<String, dynamic>> convertSteps(int stepsToConvert) async {
    final res = await post('/wallet/convert-steps', {'stepsToConvert': stepsToConvert});
    return res['data'];
  }

  Future<Map<String, dynamic>> convertOrbs(int orbsToConvert) async {
    final res = await post('/wallet/convert-orbs', {'orbsToConvert': orbsToConvert});
    return res['data'];
  }

  Future<List<dynamic>> getLeaderboard() async {
    final res = await get('/wallet/leaderboard');
    return res['data'] ?? [];
  }

  Future<List<dynamic>> getTransactions() async {
    final res = await get('/wallet/transactions');
    return res['data'] ?? [];
  }

  // ---------------------------------------------------------------------------
  // Steps (Fitness)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchSteps() async {
    final res = await get('/users/steps');
    return res['data'];
  }

  Future<Map<String, dynamic>> updateSteps(int stepsCount) async {
    final res = await post('/users/steps/update', {'stepsCount': stepsCount});
    return res['data'];
  }

  // ---------------------------------------------------------------------------
  // Bets / Challenges
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> fetchBets() async {
    final res = await get('/bet/allbets');
    return res['data'] ?? [];
  }

  Future<Map<String, dynamic>> createBet({
    required String betId,
    required String question,
    required String result,
    required DateTime resultTime,
    String? description,
    bool isTrending = false,
    String accentColor = 'orange',
  }) async {
    final res = await post('/bet/createbet', {
      'betId': betId,
      'question': question,
      'description': description ?? '',
      'result': result,
      'resultTime': resultTime.toIso8601String(),
      'isTrending': isTrending,
      'accentColor': accentColor,
    });
    return res['data'];
  }

  Future<Map<String, dynamic>> enrollInBet({
    required String betId,
    required String response,  // 'YES' | 'NO'
    required int campusCoins,
  }) async {
    final res = await post('/bet/enroll', {
      'betId': betId,
      'response': response,
      'campusCoins': campusCoins,
    });
    return res['data'];
  }

  Future<List<dynamic>> getMyBets() async {
    final res = await get('/bet/mybets');
    return res['data'] ?? [];
  }

  Future<Map<String, dynamic>> resolveBet({
    required String betId,
    required String result, // 'YES' | 'NO'
  }) async {
    final res = await post('/bet/resolve', {
      'betId': betId,
      'result': result,
    });
    return res['data'];
  }
}

// Singleton — used everywhere in the app
final apiService = ApiService();

// ---------------------------------------------------------------------------
// Helper to safely show errors in debug mode
// ---------------------------------------------------------------------------
void logApiError(String context, Object e) {
  debugPrint('[$context] API Error: $e');
}
