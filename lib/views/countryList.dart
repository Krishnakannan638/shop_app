import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CountryListScreen extends StatefulWidget {
  @override
  State<CountryListScreen> createState() => _CountryListScreenState();
}

class _CountryListScreenState extends State<CountryListScreen> {
  List<dynamic> countries = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchCountries();
  }

  void fetchCountries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final HttpLink link = HttpLink("http://localhost:3000/shop-api");

    final GraphQLClient client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    );

    const String query = """
      query {
        availableCountries {
          id
          createdAt
          updatedAt
          languageCode
          code
          type
          name
          enabled
          parent {
            id
            name
          }
          parentId
          translations {
            id
            languageCode
            name
          }
          customFields
        }
      }
    """;

    try {
      final QueryResult result = await client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        setState(() {
          _error = result.exception.toString();
          _loading = false;
        });
        return;
      }

      setState(() {
        countries = result.data?['availableCountries'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Countries",
        style: TextStyle(
          fontWeight: FontWeight.bold
        ),)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchCountries,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : countries.isEmpty
                  ? const Center(child: Text("No countries available."))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: countries.length,
                        itemBuilder: (context, index) {
                          final country = countries[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country Name
                                  Text(
                                    country['name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Country Code
                                  Text(
                                    "Code: ${country['code']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Enabled Status
                                  Row(
                                    children: [
                                      const Text(
                                        "Enabled: ",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Icon(
                                        country['enabled'] == true
                                            ? Icons.check
                                            : Icons.block,
                                        color: country['enabled'] == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Parent Region
                                  if (country['parent'] != null)
                                    Text(
                                      "Parent: ${country['parent']['name'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  const SizedBox(height: 8),
                                  // Translations
                                  if (country['translations'] != null &&
                                      country['translations'].isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Translations:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...country['translations']
                                            .map<Widget>((translation) {
                                          return Text(
                                            "- ${translation['name']} (${translation['languageCode']})",
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  // Custom Fields
                                  if (country['customFields'] != null)
                                    Text(
                                      "Custom Fields: ${country['customFields'].toString()}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
