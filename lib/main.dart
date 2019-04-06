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
        home: Home(),
        theme: ThemeData(primaryColor: Color(0xFFF5B512)));
  }
}

class Home extends StatefulWidget {
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
        recipes.add(recipe);
      }
      setState(() => meals[mealType] = recipes);
    } else {
      _fetchRecipes(mealType);
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
          title: Row(children: <Widget>[
            Text("QuickMeals"),
            Image(image: AssetImage('assets/edamam.png'))
          ]),
        ),
        body: Container(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Breakfast"),
                _buildRecipe("breakfast"),
                Text("Lunch"),
                _buildRecipe("lunch"),
                Text("Dinner"),
                _buildRecipe("dinner"),
              ],
            )));
  }

  Widget _buildRecipe(type) {
    var recipe = _getRecipe(type);
    if (recipe == null) {
      return Expanded(
          child: Container(
              alignment: Alignment.center, child: CircularProgressIndicator()));
    }
    return Expanded(
        child: InkWell(
            onTap: () async => await canLaunch(recipe.url)
                ? await launch(recipe.url)
                : throw 'Could not launch ${recipe.url}',
            child: Dismissible(
                key: Key(recipe.title),
                onDismissed: (dir) {
                  setState(() => meals[recipe.type].removeLast());
                },
                child: _recipeCard(recipe))));
  }

  Widget _recipeCard(recipe) {
    return Card(
        clipBehavior: Clip.hardEdge,
        child: Row(children: <Widget>[
          Expanded(
              child: Container(
                  margin: EdgeInsets.all(7),
                  child: Column(children: <Widget>[
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          recipe.title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 3,
                        )),
                    Spacer(flex: 1),
                    _labels(recipe.labels),
                    Text("${recipe.servings} Servings"),
                    Text("${recipe.cal} Calories"),
                  ]))),
          Expanded(
              child: Container(
                  alignment: Alignment.centerRight,
                  child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage, image: recipe.img))),
        ]));
  }

  Widget _labels(labels) {
    var icons = {
      "Vegetarian": 0,
      "Vegan": 0,
      "Low-Carb": 0,
      "Gluten-Free": 0,
    };
    return Wrap(
        children: labels
            .map<Widget>((label) => icons[label] != null
                ? SizedBox(
                    child: Image(image: AssetImage("assets/icons/$label.png")),
                    height: 30)
                : SizedBox())
            .toList());
  }
}

class Recipe {
  var type, title, url, img, servings, cal, labels;

  Recipe.fromJson(this.type, Map<String, dynamic> json)
      : url = json["url"],
        title = json["label"],
        img = json["image"],
        servings = json["yield"].round(),
        cal = json["calories"].round(),
        labels = json["dietLabels"] + json["healthLabels"];
}
