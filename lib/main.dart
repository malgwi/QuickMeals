import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:transparent_image/transparent_image.dart';
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
  Map<String, List<Recipe>> meals = Map();

  @override
  void initState() {
    super.initState();
    var query = Firestore.instance.collection("keys").document("edamam").get();
    query.then((snapshot) {
      keys = snapshot.data;
      _fetchRecipes("breakfast");
      _fetchRecipes("lunch");
      _fetchRecipes("dinner");
    });
  }

  _fetchRecipes(mealType) async {
    setState(() => meals.remove(mealType));
    var range = random.nextInt(100);
    var request =
        "http://api.edamam.com/search?q=$mealType&app_id=${keys['appId']}&app_key=${keys['appKey']}&from=$range&to=${range + 10}";
    var response = await http.get(request);
    if (response.statusCode == 200) {
      List<Recipe> recipes = List();
      for (var item in jsonDecode(response.body)["hits"]) {
        var recipe = Recipe.fromJson(mealType, item["recipe"]);
        //var recipe = Recipe(mealType, "Food", "http://google.com");
        recipes.add(recipe);
      }
      print("loaded $mealType recipes");
      setState(() => meals[mealType] = recipes);
    } else {
      throw Exception("Failed to load recipe.");
    }
  }

  _getRecipe(type) {
    try {
      if (meals[type].length < 2) {
        _fetchRecipes(type);
      }
      return meals[type].last;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("QuickMeals"),
        ),
        body: Column(
          children: <Widget>[
            _buildRecipe(_getRecipe("breakfast")),
            _buildRecipe(_getRecipe("lunch")),
            _buildRecipe(_getRecipe("dinner")),
          ],
        ));
  }

  _buildRecipe(recipe) {
    if (recipe == null) {
      return Expanded(
          child: Container(
              alignment: Alignment.center, child: CircularProgressIndicator()));
    }
    return Expanded(
        flex: 1,
        child: Dismissible(
            key: Key(recipe.title),
            onDismissed: (dir) {
              setState(() => meals[recipe.type].removeLast());
            },
            child: GestureDetector(
                onTap: () async => await canLaunch(recipe.url)
                    ? await launch(recipe.url)
                    : throw 'Could not launch ${recipe.url}',
                child: Card(
                    child: Row(children: <Widget>[
                  Expanded(
                      child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage, image: recipe.img)),
                  Expanded(
                      child: Column(children: <Widget>[
                    Center(
                        child: Text(
                      recipe.title,
                      textAlign: TextAlign.center,
                    )),
                    Container(
                        child: Column(children: <Widget>[
                      Text("Servings: ${recipe.servings}"),
                      Text("Total Calories: ${recipe.cal}"),
                    ]))
                  ])),
                ])))));
  }
}

class Recipe {
  var type;
  var title;
  var url;
  var img;
  int servings;
  int cal;
  var labels;

  Recipe(this.type, this.title, this.url);

  Recipe.fromJson(this.type, Map<String, dynamic> json)
      : url = json["url"],
        title = json["label"],
        img = json["image"],
        servings = json["yield"].round(),
        cal = json["calories"].round(),
        labels = json["dietLabels"] + json["healthLabels"];
}
