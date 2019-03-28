import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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
  var random = Random();
  var keys;
  Map<String, Recipe> meals = Map();

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildRecipe(meals["breakfast"]),
            _buildRecipe(meals["lunch"]),
            _buildRecipe(meals["dinner"]),
          ],
        ));
  }

  fetchRecipe(mealType) async {
    setState(() => meals.remove(mealType));
    var range = random.nextInt(100);
    var request =
        "http://api.edamam.com/search?q=$mealType&app_id=${keys['appId']}&app_key=${keys['appKey']}&from=$range&to=${range + 1}";
    var response = await http.get(request);
    if (response.statusCode == 200) {
      var recipe = Recipe.fromJson(
          mealType, jsonDecode(response.body)["hits"][0]["recipe"]);
      //var recipe = Recipe(mealType, "Food", "http://google.com");
      print("New Recipe: ${recipe.title}");
      setState(() => meals[mealType] = recipe);
    } else {
      throw Exception("Failed to load recipe.");
    }
  }

  _buildRecipe(recipe) {
    if (recipe == null) return Expanded(child: CircularProgressIndicator());
    return Expanded(
        flex: 1,
        child: Dismissible(
            key: Key(recipe.title),
            onDismissed: (dir) {
              setState(() => meals.remove(recipe.type));
              fetchRecipe(recipe.type);
            },
            child: GestureDetector(
                onTap: () async => await canLaunch(recipe.url)
                    ? await launch(recipe.url)
                    : throw 'Could not launch ${recipe.url}',
                child: Card(child: Text(recipe.title)))));
  }
}

class Recipe {
  var type;
  var title;
  var url;

  Recipe(this.type, this.title, this.url);

  Recipe.fromJson(this.type, Map<String, dynamic> json)
      : url = json["url"],
        title = json["label"];
}
