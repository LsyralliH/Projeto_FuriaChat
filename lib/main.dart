import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; 

// Substitua 'INSIRA_SUA_CHAVE_AQUI' pela chave real de API, mas nunca expõe esta chave no código!
const apiKey = 'INSIRA_SUA_CHAVE_AQUI';
bool useMock = true;

Future<Map<String, dynamic>> loadMockJson() async {
  String jsonString = await rootBundle.loadString('assets/mock_furia.json');
  return json.decode(jsonString);
}

Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url); // Usando Uri.parse para criar uma instância de Uri
  
  // Usando o canLaunch e launch com Uri
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri); // Usando launchUrl com Uri
  } else {
    throw 'Não foi possível abrir o link: $url';
  }
}

//1
Future<String> fetchNextMatch() async {
  if (useMock) {
    final mockJson = await loadMockJson();
    final matches = mockJson['matches'] as List<dynamic>;
    final nextMatch = matches.first;
    final opponents = nextMatch['opponents'] as List<dynamic>;
    final opponentNames = opponents
        .map((opponent) => opponent['opponent']['name'])
        .where((name) => !name.toString().toLowerCase().contains('furia'))
        .join(' vs ');

    final scheduledAt = nextMatch['scheduled_at'];
    final dateTime = DateTime.parse(scheduledAt).toLocal();

    return 'O próximo jogo da FURIA é contra $opponentNames em '
           '${dateTime.day}/${dateTime.month}/${dateTime.year} às '
           '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}.';
  }
  final url = Uri.parse('https://api.pandascore.co/csgo/matches/upcoming?per_page=100');
  final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});

  if (response.statusCode == 200) {
    final List<dynamic> matches = jsonDecode(response.body);
    final furiaMatches = matches.where((match) {
      final opponents = match['opponents'] as List<dynamic>;
      return opponents.any((opponent) =>
          opponent['opponent'] != null &&
          opponent['opponent']['name'] != null &&
          opponent['opponent']['name'].toString().toLowerCase().contains('furia')|| opponent['opponent']['acronym'].toString().toLowerCase().contains('fur'));
    }).toList();

    if (furiaMatches.isNotEmpty) {
      final nextMatch = furiaMatches.first;
      final opponents = nextMatch['opponents'] as List<dynamic>;
      final opponentNames = opponents
          .map((opponent) => opponent['opponent']['name'])
          .where((name) => !name.toString().toLowerCase().contains('furia'))
          .join(' vs ');

      final scheduledAt = nextMatch['scheduled_at'];
      final dateTime = DateTime.parse(scheduledAt).toLocal();

      return 'O próximo jogo da FURIA é contra $opponentNames em '
             '${dateTime.day}/${dateTime.month}/${dateTime.year} às '
             '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}.';
    } else {
      return 'Não há partidas futuras da FURIA no momento.';
    }
  } else {
    return 'Erro ao acessar a API (${response.statusCode})';
  }
}

//2
Future<String> fetchTeamRank() async {
  if (useMock) {
    final mockJson = await loadMockJson();
    final furiaTeam = mockJson['teams'].firstWhere((team) {
      final name = team['name'].toString().toLowerCase();
      return name.contains('furia');
    });

    final rank = furiaTeam['ranking'] ?? 'N/A';
    return 'A FURIA está atualmente no rank $rank.';
  }
  final url = Uri.parse('https://api.pandascore.co/csgo/teams?search=furia');
  final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});

  if (response.statusCode == 200) {
    final List<dynamic> teams = jsonDecode(response.body);
    final furiaTeam = teams.firstWhere(
      (team) {
        final name = team['name']?.toString().toLowerCase() ?? '';
        final acronym = team['acronym']?.toString().toLowerCase() ?? '';
        final slug = team['slug']?.toString().toLowerCase() ?? '';
        return name.contains('furia') || acronym.contains('fur') || slug.contains('furia');

    },
    orElse: () => null,
  );


    if (furiaTeam != null) {
      final rank = furiaTeam['ranking'] ?? furiaTeam['current_rank'] ?? 'N/A';
      return 'A FURIA está atualmente no rank $rank.';
    } else {
      return 'Não foi possível encontrar o time FURIA.';
    }
  } else {
    return 'Erro ao acessar a API (${response.statusCode})';
  }
}

//3
Future<String> fetchPlayers() async {
  if (useMock) {
    final mockJson = await loadMockJson();
    final players = mockJson['players'] as List<dynamic>;
    final playerNames = players.map((player) => player['name']).join(', ');
    return 'Jogadores atuais da FURIA: $playerNames.';
  }
  final url = Uri.parse('https://api.pandascore.co/csgo/teams?search=furia');
  final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});

  if (response.statusCode == 200) {
    final List<dynamic> teams = jsonDecode(response.body);
    final furiaTeam = teams.firstWhere(
      (team) {
        final name = team['name']?.toString().toLowerCase() ?? '';
        final acronym = team['acronym']?.toString().toLowerCase() ?? '';
        final slug = team['slug']?.toString().toLowerCase() ?? '';
        return name.contains('furia') || acronym.contains('fur') || slug.contains('furia');
      },
      orElse: () => null,
    );

    if (furiaTeam != null) {
      final teamId = furiaTeam['id'];
      final playersUrl = Uri.parse('https://api.pandascore.co/csgo/teams/$teamId/players');
      final playersResponse = await http.get(playersUrl, headers: {'Authorization': 'Bearer $apiKey'});

      if (playersResponse.statusCode == 200) {
        final List<dynamic> players = jsonDecode(playersResponse.body);
        final playerNames = players.map((player) => player['name']).join(', ');
        return 'Jogadores atuais da FURIA: $playerNames.';
      } else {
        return 'Erro ao acessar os jogadores (${playersResponse.statusCode}).';
      }
    } else {
      return 'Time FURIA não encontrado.';
    }
  } else {
    return 'Erro ao acessar a API (${response.statusCode}).';
  }
}

//4
Future<String> fetchTournaments() async {
  if (useMock) {
    final mockJson = await loadMockJson();
    final tournaments = mockJson['tournaments'] as List<dynamic>;
    final tournamentNames = tournaments.map((t) => t['name']).join(', ');
    return 'Próximos campeonatos da FURIA: $tournamentNames.';
  }
  final url = Uri.parse('https://api.pandascore.co/csgo/tournaments/upcoming?per_page=50');
  final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});

  if (response.statusCode == 200) {
    final List<dynamic> tournaments = jsonDecode(response.body);
    final furiaTournaments = tournaments.where((tournament) {
      final name = (tournament['name'] ?? '').toString().toLowerCase();
      return name.contains('furia');
    }).toList();

    if (furiaTournaments.isNotEmpty) {
      final tournamentNames = furiaTournaments.map((t) => t['name']).join(', ');
      return 'Próximos campeonatos da FURIA: $tournamentNames.';
    } else {
      return 'Nenhum campeonato da FURIA encontrado entre os próximos.';
    }
  } else {
    return 'Erro ao acessar a API (${response.statusCode}).';
  }
}

//5
Future<String> fetchLastResults() async {
  if (useMock) {
    final mockJson = await loadMockJson();
    final results = mockJson['results'] as List<dynamic>;
    final lastMatch = results.first;
    final opponents = (lastMatch['opponents'] as List<dynamic>)
        .map((opponent) => opponent['opponent']['name'])
        .join(' vs ');
    final winner = lastMatch['winner']?['name'] ?? 'Sem vencedor registrado';
    final scoreList = (lastMatch['results'] as List<dynamic>?);
    final score = scoreList != null
        ? scoreList.map((result) => '${result['team']['name']}: ${result['score']}').join(' - ')
        : '';


    return 'Último jogo: $opponents.\nVencedor: $winner.\nPlacar: $score.';
  }
  final url = Uri.parse('https://api.pandascore.co/csgo/matches/past?per_page=50');
  final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});

  if (response.statusCode == 200) {
    final List<dynamic> matches = jsonDecode(response.body);
    final furiaMatches = matches.where((match) {
      final opponents = match['opponents'] as List<dynamic>?;
      return opponents != null && opponents.any((opponent) =>
        opponent['opponent'] != null &&
        (opponent['opponent']['name'] ?? '').toString().toLowerCase().contains('furia')
      );
    }).toList();

    if (furiaMatches.isNotEmpty) {
      final lastMatch = furiaMatches.first;
      final opponents = (lastMatch['opponents'] as List<dynamic>)
          .map((opponent) => opponent['opponent']['name'])
          .join(' vs ');
      final winner = lastMatch['winner']?['name'] ?? 'Sem vencedor registrado';
      final score = lastMatch['results']
          ?.map((result) => '${result['team']['name']}: ${result['score']}')
          .join(' - ') ?? '';

      return 'Último jogo: $opponents.\nVencedor: $winner.\nPlacar: $score.';
    } else {
      return 'Nenhum jogo recente da FURIA encontrado.';
    }
  } else {
    return 'Erro ao acessar a API (${response.statusCode}).';
  }
}


//6
Future<String> fetchLastMatchStats() async {
  if (useMock) {
    final mockJson = await loadMockJson();
    final results = mockJson['results'] as List<dynamic>?;

    if (results == null || results.isEmpty) {
      return 'Nenhum resultado encontrado no mock.';
    }

    final matchStats = results.first['match_stats'] as Map<String, dynamic>?;

    if (matchStats == null) {
      return 'Dados de estatísticas não encontrados no mock.';
    }

    final totalKills = matchStats['total_kills'] as Map<String, dynamic>?;
    final mostKills = matchStats['most_kills_player'] as Map<String, dynamic>?;
    final mapScores = matchStats['map_scores'] as List<dynamic>?;

    if (totalKills == null || mostKills == null || mapScores == null) {
      return 'Dados incompletos nas estatísticas do mock.';
    }

    final furiaKills = totalKills['FURIA'];
    final opponentKills = totalKills.entries.firstWhere((entry) => entry.key != 'FURIA').value;
    final topPlayer = mostKills['name'];
    final topKills = mostKills['kills'];

    final maps = mapScores.map((map) {
      final name = map['map'];
      final fur = map['FURIA'];
      final opp = map.entries.firstWhere((e) => e.key != 'map' && e.key != 'FURIA').value;
      return '$name: FURIA $fur x $opp';
    }).join('\n');

    return '''
Último jogo (Mock):
Kills totais - FURIA: $furiaKills, Oponente: $opponentKills
Jogador com mais kills: $topPlayer ($topKills kills)
Pontuação por mapa:
$maps
''';
  }
    final url = Uri.parse('https://api.pandascore.co/csgo/matches/past?per_page=50');
  final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});

  if (response.statusCode == 200) {
    final List<dynamic> matches = jsonDecode(response.body);
    final furiaMatches = matches.where((match) {
      final opponents = match['opponents'] as List<dynamic>?;
      return opponents != null && opponents.any((opponent) =>
        opponent['opponent'] != null &&
        (opponent['opponent']['name'] ?? '').toString().toLowerCase().contains('furia')
      );
    }).toList();

    if (furiaMatches.isNotEmpty) {
      final lastMatch = furiaMatches.first;
      final rounds = lastMatch['number_of_games'] ?? 'N/A';
      final status = lastMatch['status'] ?? 'N/A';
      final winner = lastMatch['winner']?['name'] ?? 'Sem vencedor registrado';

      return 'Último jogo:\nStatus: $status\nRodadas jogadas: $rounds\nVencedor: $winner';
    } else {
      return 'Não há estatísticas recentes da FURIA.';
    }
  } else {
    return 'Erro ao acessar a API (${response.statusCode}).';
  }
}


//7
Future<String> fetchSocialMedia() async {
  return '''
Siga a FURIA nas redes sociais:

- Instagram: https://www.instagram.com/furiagg/
- Twitter (X): https://x.com/furia
- YouTube: https://www.youtube.com/channel/UCE4elIT7DqDv545IA71feHg
- Site oficial: https://www.furia.gg/
  ''';
}

Future<String> fetchGritos() async {
  return '''
É FURIAAAAA 🔥
  ''';
}
void main() {
  runApp(const FuriaBotApp());
}

class FuriaBotApp extends StatelessWidget {
  const FuriaBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FURIA ChatBot',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromARGB(255, 3, 32, 163),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 3, 17, 79),
        ),
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 3, 32, 163),
          secondary: const Color.fromARGB(255, 3, 32, 163),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          surface: const Color.fromARGB(255, 0, 0, 0),
          onSurface: Colors.white,
        ),
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController controller = TextEditingController();

  void sendMessage(String text) {
    setState(() {
      messages.add({'sender': 'Você', 'text': text});
      handleBotResponse(text);
    });
    controller.clear();
  }

  void handleBotResponse(String input) async {
    String response;

    input = input.toLowerCase();
      bool opcao = input.contains("1") || input.contains("2") || input.contains("3") || input.contains("4") || input.contains("5") || input.contains("6") || input.contains("7") || input.contains("8");
    // Lógica para obter a resposta baseada na entrada do usuário
    if (input.contains("1")) {
      response = await fetchNextMatch();
    } else if (input.contains("2")) {
      response = await fetchTeamRank();
    } else if (input.contains("3")) {
      response = await fetchPlayers();
    } else if (input.contains("4")) {
      response = await fetchTournaments();
    } else if (input.contains("5")) {
      response = await fetchLastResults();
    } else if (input.contains("6")) {
      response = await fetchLastMatchStats();
    } else if (input.contains("7")) {
      response = await fetchSocialMedia();
    } else if (input.contains("8")) {
      response = await fetchGritos();
    } else {
      response = "Olá Furiosoooo🖤!!!!\n\nO que deseja saber:\n\t1 - Qual o próximo jogo?\n\t2 - Rank da FURIA\n\t3 - Quais são os jogadores?\n\t4 - Próximos campeonatos\n\t5 - Últimos resultados\n\t6 - Estatísticas no último jogo\n\t7 - Redes sociais da FURIA\n\t8 - Vibração Furiosa";
    }
    
    setState(() {
      messages.add({'sender': 'FURIABot', 'text': response});

      if (opcao) {
      messages.add({
        'sender': 'FURIABot',
        'text': "Deseja mais alguma coisa?\n\n\t1 - Qual o próximo jogo?\n\t2 - Rank da FURIA\n\t3 - Quais são os jogadores?\n\t4 - Próximos campeonatos\n\t5 - Últimos resultados\n\t6 - Estatísticas no último jogo\n\t7 - Redes sociais da FURIA\n\t8 - Vibração Furiosa"
      });
    }
  });
}
  

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/image_furia.png',
              height: 40,
            ),
            Image.asset(
              'assets/images/furia_novonome.png',
              height: 35,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/furias.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isBot = msg['sender'] == 'FURIABot';
                    final message = msg['text']!;

                    // Expressão regular para encontrar URLs na mensagem
                    final urlPattern = r'(https?://[^\s]+)';
                    final regex = RegExp(urlPattern);
                    final matches = regex.allMatches(message);

                    // Criando uma lista de TextSpan
                    List<TextSpan> textSpans = [];
                    int start = 0;

                    // Loop para dividir a mensagem e criar partes clicáveis (URLs)
                    for (var match in matches) {
                      // Adiciona a parte não-URL primeiro
                      if (match.start > start) {
                        textSpans.add(TextSpan(
                          text: message.substring(start, match.start),
                          style: TextStyle(color: Colors.white),
                        ));
                      }

                      // Verifique a URL e associe um nome de rede social específico
                      String linkText = match.group(0)!;
                      String displayText = linkText;

                      if (linkText.contains("instagram.com")) {
                        displayText = "@furiagg"; // Nome do Instagram
                      } else if (linkText.contains("x.com")) {
                        displayText = "@FURIA"; // Nome do Twitter (X)
                      } else if (linkText.contains("youtube.com")) {
                        displayText = "FURIA"; // Nome do YouTube
                      } else if (linkText.contains("furia.gg")) {
                        displayText = "furia.gg"; // Nome do site oficial
                      }

                      // Adiciona a parte da URL como clicável, mas exibe apenas o nome
                      textSpans.add(TextSpan(
                        text: displayText,
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchURL(linkText); // A URL completa será aberta
                          },
                      ));

                      start = match.end;
                    }

                    // Adiciona a parte restante da mensagem após o último match
                    if (start < message.length) {
                      textSpans.add(TextSpan(
                        text: message.substring(start),
                        style: TextStyle(color: Colors.white),
                      ));
                    }

                    return Align(
                      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isBot
                              ? Color.fromARGB(255, 3, 32, 163)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: textSpans,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "Digite alguma coisa...",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color.fromARGB(255, 3, 13, 60),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => sendMessage(controller.text),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
