import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lab_pemmob/data/dummy_data.dart';
import 'package:lab_pemmob/models/anime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateProvider extends ChangeNotifier {
  List<Anime> _favorites = [];
  static const String _storageKey = 'favorite_anime_list';

  String _selectedGenre = "All";

  String _homeSearchQuery = "";
  String _favoriteSearchQuery = "";

  List<Anime> get favorites => _favorites;
  String get selectedGenre => _selectedGenre;
  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  AppStateProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_storageKey);

      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites = decoded.map((item) {
          return Anime(
            id: item['id'],
            title: item['title'],
            imagePath: item['imagePath'],
            genre: item['genre'],
            rating: item['rating'],
            totalEpisodes: item['totalEpisodes'],
            description: item['description'],
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> favoritesJson = _favorites.map((anime) {
        return {
          'id': anime.id,
          'title': anime.title,
          'imagePath': anime.imagePath,
          'genre': anime.genre,
          'rating': anime.rating,
          'totalEpisodes': anime.totalEpisodes,
          'description': anime.description,
        };
      }).toList();

      await prefs.setString(_storageKey, json.encode(favoritesJson));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  /// Check if anime is in favorites
  bool isFavorite(String animeId) {
    return _favorites.any((anime) => anime.id == animeId);
  }

  /// Toggle favorite status
  void toggleFavorite(Anime anime) {
    if (isFavorite(anime.id)) {
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
  }

  /// Add anime to favorites
  void addFavorite(Anime anime) {
    if (!isFavorite(anime.id)) {
      _favorites.add(anime);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFavorite(String animeId) {
    _favorites.removeWhere((anime) => anime.id == animeId);
    _saveFavorites();
    notifyListeners();
  }

  int get favoritesCount => _favorites.length;

  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  void setHomeSearchQuery(String query) {
    _homeSearchQuery = query;
    notifyListeners();
  }

  void setFavoriteSearchQuery(String query) {
    _favoriteSearchQuery = query;
    notifyListeners();
  }

  List<Anime> getFilteredAnimeForHome() {
    List<Anime> result = DummyData.animeList;

    if (_selectedGenre != "All") {
      result = result.where((anime) {
        final genres = anime.genre.split(',').map((g) => g.trim()).toList();
        return genres.contains(_selectedGenre);
      }).toList();
    }

    if (_homeSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title.toLowerCase().contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

  List<Anime> getFilteredFavorites() {
    List<Anime> result = _favorites;

    if (_favoriteSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title.toLowerCase().contains(_favoriteSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }
}