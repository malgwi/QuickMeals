import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

void main() => runApp(QuickMeals());

class QuickMeals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "QuickMeals",
      home: Home(title: "QuickMeals"),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var keys;
  var breakfast, lunch, dinner;

  @override
  void initState() {
    super.initState();
    var query = Firestore.instance.collection("keys").document("edamam").get();
    query.then((snapshot) {
      keys = snapshot.data;
      fetchRecipe("breakfast");
      fetchRecipe("lunch");
      fetchRecipe("dinner");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("QuickMeals"),
        ),
        body: Column(
          children: <Widget>[
            _buildRecipe(breakfast),
            _buildRecipe(lunch),
            _buildRecipe(dinner),
          ],
        ));
  }

  fetchRecipe(query) async {
    var request =
        "http://api.edamam.com/search?q=$query&app_id=${keys['appId']}&app_key=${keys['appKey']}&to=1";
    /*
    var response = await http.get(request);
    if (response.statusCode == 200) {
      var recipe =
          Recipe.fromJson(jsonDecode(response.body)["hits"][0]["recipe"]);
          */
    var recipe = Recipe("www.google.com", "Food");
    switch (query) {
      case "breakfast":
        setState(() => breakfast = recipe);
        break;
      case "lunch":
        setState(() => lunch = recipe);
        break;
      case "dinner":
        setState(() => dinner = recipe);
    }
    /*
    } else {
      throw Exception("Failed to load recipe.");
    }
    */
  }

  _buildRecipe(recipe) {
    if (recipe == null) return CircularProgressIndicator();
    return Text(recipe.title);
  }
}

class Recipe {
  var url;
  var title;

  Recipe(this.url, this.title);

  Recipe.fromJson(Map<String, dynamic> json)
      : url = json["url"],
        title = json["label"];
}
