# Visible

> Acessibilidade urbana mapeada pela comunidade.

App mobile em **Flutter** para mapear, de forma colaborativa, problemas de
acessibilidade e de mobilidade urbana: calçadas quebradas, rampas danificadas,
falta de piso tátil, obstáculos e passagens bloqueadas. O app mostra cada
problema no mapa conforme o impacto que ele tem para **quem** está andando pela
cidade.

O projeto começou com o nome *Cidade Invisível* e foi renomeado para
**Visible** depois da apresentação.

**Projeto acadêmico.** Foi feito para a disciplina de **Desenvolvimento Mobile**
(8º período), no trabalho *"Meu Smartphone Inteligente"*, e apresentado em
**10/11/2026**. O objetivo era construir um app que usasse recursos nativos do
celular (câmera, GPS, notificação local e acelerômetro) e os integrasse numa
solução real.

---

## Sumário

- [A ideia](#a-ideia)
- [O que o app faz](#o-que-o-app-faz)
- [Recursos nativos (requisitos do trabalho)](#recursos-nativos-requisitos-do-trabalho)
- [Como os recursos se integram](#como-os-recursos-se-integram)
- [Arquitetura](#arquitetura)
- [Regras de negócio](#regras-de-negócio)
- [Servidor local e API](#servidor-local-e-api)
- [Como rodar](#como-rodar)
- [Testes](#testes)
- [Desafios e decisões técnicas](#desafios-e-decisões-técnicas)
- [Limitações e próximos passos](#limitações-e-próximos-passos)
- [Créditos](#créditos)

---

## A ideia

Um buraco na calçada é só um incômodo para um pedestre, mas pode impedir o
caminho de um cadeirante. Uma calçada sem piso tátil passa despercebida para a
maioria das pessoas e é um risco para quem tem deficiência visual. Esses
problemas são **invisíveis** para quem não é afetado por eles, e por isso
raramente são registrados ou corrigidos.

O Visible propõe três coisas:

1. **Registrar é rápido.** Uma foto, a localização automática e uma categoria.
   Tudo em três passos.
2. **O mapa muda conforme o perfil.** Quem escolhe "cadeirante" vê rampas e
   degraus em destaque. Quem escolhe "deficiência visual" vê obstáculos e falta
   de piso tátil. O mesmo problema tem prioridade diferente para cada pessoa.
3. **A comunidade mantém o mapa vivo.** Outras pessoas confirmam que o problema
   ainda existe, marcam como resolvido ou denunciam registros falsos. Registros
   antigos e sem confirmação perdem prioridade aos poucos.

O perfil de mobilidade é **opcional** e fica só no aparelho. O app funciona sem
cadastro e sem login.

## O que o app faz

| Tela | O que tem |
|---|---|
| **Onboarding** | Boas-vindas e escolha opcional do perfil de mobilidade |
| **Início** | Botão principal de registro, atalhos, problemas próximos em destaque, estatísticas e dica do dia |
| **Mapa** | Mapa OpenStreetMap com marcadores por categoria, filtros, destaque conforme o impacto no seu perfil e alertas de problemas por perto |
| **Registrar** | Fluxo em 3 passos: foto → local (GPS) → categoria e gravidade. Avisa se já existe um registro parecido a menos de 25 m |
| **Detalhes do problema** | Foto, distância, idade, confirmações. Ações: "ainda existe", "foi resolvido" e "denunciar" |
| **Trajeto** (observação de trajeto) | Usa acelerômetro e GPS durante uma caminhada para detectar trancos (possíveis buracos ou desníveis) e sugerir registros |
| **Histórico** | Registros feitos e confirmados neste aparelho |
| **Perfil** | Perfil de mobilidade, preferências de notificação e privacidade |
| **Diagnóstico de recursos** | Uma tela de teste para cada recurso nativo: câmera, GPS, notificação e acelerômetro |

As seis categorias de problema são **Pavimentação**, **Acessibilidade**,
**Obstáculos**, **Sinalização**, **Desníveis** e **Bloqueios**. Os cinco perfis
são **Cadeirante**, **Pedestre**, **Idoso**, **Deficiência visual** e **Perfil
geral**.

## Recursos nativos (requisitos do trabalho)

| Requisito | Pacote | Onde é usado | Arquivos |
|---|---|---|---|
| **Câmera:** capturar e exibir foto | [`camera`](https://pub.dev/packages/camera) | Foto do problema no registro, com pré-visualização ao vivo | `lib/features/camera/` |
| **GPS:** latitude e longitude | [`geolocator`](https://pub.dev/packages/geolocator) | Local do registro, distância até cada problema, centro do mapa | `lib/core/services/location_service.dart` |
| **Notificação local** | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | Aviso de problema próximo que afeta seu perfil e de tranco detectado no trajeto | `lib/core/services/notification_service.dart` |
| **Acelerômetro:** eixos X, Y e Z ao vivo | [`sensors_plus`](https://pub.dev/packages/sensors_plus) (Android) e `devicemotion` (web) | Valores ao vivo no diagnóstico e detecção de trancos na observação de trajeto | `lib/core/services/motion/`, `lib/features/sensors/` |

Outros pacotes:

| Pacote | Para quê |
|---|---|
| `permission_handler` | Pedir permissão de câmera |
| `flutter_map` + `latlong2` | Mapa com tiles do OpenStreetMap (sem chave de API) |
| `http` | Comunicação com o servidor local |
| `shared_preferences` | Perfil, preferências, id do aparelho e cache offline |
| `path_provider` | Arquivo temporário da foto |
| `web` | Acesso ao `devicemotion` do navegador (iPhone) |
| `intl` | Formatação de datas |

## Como os recursos se integram

O desafio extra do trabalho era usar os recursos **juntos**, não só cada um
isolado. No app, um único registro passa pelos quatro:

```
 Câmera ──► foto do problema
   │
 GPS ─────► latitude/longitude do registro ──► servidor (SQLite)
                                                    │
                     outros aparelhos recebem ◄─────┘ (atualização a cada 6 s)
                                │
                   GPS calcula a distância até você
                                │
     problema a até 300 m e de impacto alto no seu perfil?
                                │
                      Notificação local 🔔

 Acelerômetro + GPS ──► a observação de trajeto detecta um tranco
                        longe de qualquer problema já registrado
                         ──► notificação local
                         ──► botão "Verificar" abre o registro com o local preenchido
```

## Arquitetura

```
lib/
├── main.dart                 # inicializa notificações e sobe o app
├── app/
│   ├── app.dart              # MaterialApp, AppScope (InheritedNotifier)
│   ├── routes.dart           # rotas das telas de diagnóstico
│   └── theme/app_theme.dart  # tema Material 3 em azul-marinho e tons neutros
├── core/
│   ├── services/
│   │   ├── app_state.dart          # ChangeNotifier: perfil, preferências
│   │   ├── issue_repository.dart   # registros: API + cache + polling
│   │   ├── api_config.dart         # resolve a URL da API por plataforma
│   │   ├── location_service.dart   # GPS com timeout e erros amigáveis
│   │   ├── notification_service.dart
│   │   └── motion/                 # acelerômetro: Android (sensors_plus) e web (devicemotion)
│   └── utils/
│       ├── geo.dart          # distância (haversine), "há 3 dias"
│       └── relevance.dart    # pontuação de prioridade por perfil
├── models/                   # UrbanIssue, IssueCategory, MobilityProfile, SensorEvent
├── features/                 # uma pasta por tela
│   ├── home/  map/  issue_reporting/  issue_details/  sensors/
│   ├── camera/  location/  notifications/  diagnostics/
│   └── onboarding/  contributions/  profile/  shell/
└── shared/widgets/           # componentes reutilizáveis
server/
└── server.py                 # API + SQLite + entrega do app web
test/                         # testes de widget e de regras de negócio
```

Algumas escolhas:

- **Estado simples.** Um `ChangeNotifier` (`AppState`) exposto por um
  `InheritedNotifier` (`AppScope`), sem biblioteca externa de gerenciamento de
  estado. Para o tamanho do app, isso é suficiente.
- **Serviços isolados das telas.** As telas não chamam `geolocator` nem `http`
  diretamente. Isso permite testar o repositório com uma API falsa.
- **Uma pasta por feature.** Cada pessoa do grupo podia trabalhar numa tela sem
  gerar conflito com as outras.
- **Acelerômetro com duas implementações.** `MotionSource` escolhe por import
  condicional: `sensors_plus` no Android e o evento `devicemotion` no navegador,
  porque o Safari do iPhone não suporta a API que o `sensors_plus` usa na web.

## Regras de negócio

**Prioridade por perfil.** Cada problema recebe uma pontuação:

```
prioridade = impacto no perfil × gravidade × decaimento por idade

impacto:      alto = 3, médio = 2, baixo = 1   (depende da categoria e do perfil)
gravidade:    leve = 1, moderada = 2, grave = 3
decaimento:   confirmado há até 30 dias = 1,0 · até 90 dias = 0,7 · mais antigo = 0,4
```

Essa pontuação ordena os destaques da tela inicial e a lista de alertas do mapa.
No mapa, a cor do marcador indica a categoria. Problemas de impacto alto para o
seu perfil ficam em destaque, e os de impacto baixo ficam esmaecidos.

**Alerta de proximidade:** ao abrir o mapa, se houver um problema não resolvido
de impacto alto para o seu perfil a até 300 m, o app envia uma notificação local
(uma vez por sessão, e só se o aviso estiver ligado no Perfil).

**Outras regras:**

- **Duplicados:** ao registrar, o app avisa se já existe um problema da mesma
  categoria a menos de 25 m e sugere confirmar o existente em vez de criar outro.
- **Confirmação única:** cada aparelho confirma um problema só uma vez. O
  servidor garante isso pela chave (registro, id do aparelho).
- **Confirmar renova:** confirmar "ainda existe" atualiza a data da última
  confirmação e reabre um problema marcado como resolvido.
- **Distância:** calculada com a fórmula de haversine.
- **Privacidade:** não há conta. O aparelho é identificado por um id aleatório
  gerado localmente, e o perfil de mobilidade nunca é enviado ao servidor.

## Servidor local e API

Para que os registros e fotos fossem **compartilhados entre aparelhos** sem
depender de serviço pago ou de cadastro em nuvem, o projeto tem um servidor em
Python que usa só a biblioteca padrão (`http.server` + `sqlite3`). O mesmo
servidor entrega o app web, então app e API ficam na mesma origem e não há
problema de CORS.

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/api/health` | Verifica se o servidor está no ar |
| `GET` | `/api/issues?deviceId=…` | Lista os registros (com `confirmedByMe` para o aparelho) |
| `POST` | `/api/issues` | Cria um registro (JSON com foto em base64) |
| `GET` | `/api/photos/<id>` | Devolve a foto de um registro |
| `POST` | `/api/issues/<id>/confirm` | "Ainda existe" (uma vez por aparelho) |
| `POST` | `/api/issues/<id>/resolve` | Marca como resolvido |
| `POST` | `/api/issues/<id>/flag` | Denuncia o registro |

O app consulta a lista a cada 6 segundos. Se o servidor cair, ele continua
abrindo com os últimos dados salvos e mostra o aviso "Sem conexão com o
servidor".

Os dados ficam em `server/data/`, que o git ignora.

## Como rodar

**Requisitos:** Flutter 3.47+ (Dart 3.13+), Python 3 e, para Android, o Android
SDK com um emulador.

```bash
flutter pub get
```

### 1. Servidor

```bash
python3 server/server.py --port 8080
```

### 2. Android (emulador)

O emulador enxerga o computador em `10.0.2.2`, que já é o endereço padrão da API:

```bash
flutter run -d <id-do-emulador>
```

Em um celular Android real, informe o IP do computador na rede:

```bash
flutter run --dart-define=API_URL=http://<ip-do-pc>:8080
```

### 3. Web (e iPhone)

```bash
flutter build web --release
python3 server/server.py --port 8080      # serve o app e a API juntos
```

Abra `http://localhost:8080`.

Para abrir no celular, publique a porta com um túnel HTTPS, por exemplo
`ngrok http 8080`. **Câmera, GPS e sensores só funcionam em HTTPS** no
navegador do celular. No iPhone, o acesso ao acelerômetro precisa ser liberado
no botão "Ativar sensores", porque o Safari só pede essa permissão depois de um
toque do usuário.

> Use o build de **release**. O servidor de desenvolvimento do Flutter faz
> centenas de requisições por carregamento e estoura o limite do plano gratuito
> do ngrok.

### Deploy no GitHub Pages

O workflow `.github/workflows/deploy-web.yml` roda `flutter analyze`, os testes e
o build web a cada push na `main` e publica no GitHub Pages. É preciso ativar
**Settings → Pages → Source: GitHub Actions**.

O Pages só serve arquivos estáticos. Sem o servidor Python, o app abre, mas sem
registros compartilhados.

## Testes

```bash
flutter analyze
flutter test
```

Os testes cobrem:

- a tela de onboarding (teste de widget);
- a pontuação de prioridade por perfil e o decaimento por idade;
- o cálculo de distância (haversine);
- a serialização dos registros;
- o repositório com uma API falsa: criação, confirmação, detecção de duplicados
  e funcionamento offline com cache.

## Desafios e decisões técnicas

| Problema | Solução |
|---|---|
| O grupo só tinha iPhone e o desenvolvimento era feito em Linux, sem Xcode | Versão **web** do app, aberta no iPhone por um túnel HTTPS. O Android ficou no emulador, para a notificação nativa |
| Câmera, GPS e sensores bloqueados no Safari | Esses recursos exigem HTTPS: túnel com ngrok |
| Pré-visualização da câmera não aparecia ao vivo na web | A prévia é uma *platform view* e não pode ser redimensionada com `FittedBox`. Passou a usar `AspectRatio`, sem áudio e com tratamento de erro e botão de tentar de novo |
| `sensors_plus` não funciona no Safari | Implementação própria com o evento `devicemotion` e `DeviceMotionEvent.requestPermission()` chamado dentro do toque |
| Compartilhar registros entre aparelhos sem Firebase | Servidor Python + SQLite local, com cache offline no app |
| Android bloqueava HTTP sem TLS para o servidor local | `usesCleartextTraffic` no `AndroidManifest.xml` (aceitável só para o ambiente local da apresentação) |
| Notificações na web | O navegador não tem notificação local equivalente. Na web o app mostra um aviso interno; a notificação de verdade é demonstrada no Android |

## Limitações e próximos passos

**Limitações conhecidas:**

- O servidor é local e não tem autenticação. Ele serve para demonstração, não
  para produção.
- "Resolvido" e "denunciar" não exigem consenso de várias pessoas.
- Na web, a notificação é só um aviso dentro do app.
- O app não foi testado em iOS nativo, só no Safari do iPhone.

**Ideias para continuar:**

- classificação automática da foto por IA;
- "resolver com prova", com foto do depois;
- pontos e selos para quem contribui;
- notificações push (FCM ou OneSignal);
- rotas que evitam os problemas do seu perfil;
- painel para a prefeitura acompanhar os registros.

## Créditos

Projeto desenvolvido em grupo para a disciplina de Desenvolvimento Mobile,
8º período.

- **Integrantes:**
  - Caique Moran de Souza
  - Elton Dourado de Azevedo Filho
  - Emanuel Corrêa Carneiro
  - Felipe da Silva Pereira Alves
  - Ygor Gomes Rocha
- **Professor:** Renato
- **Repositório original do grupo:** [fdasilvapa/cidade-invisivel](https://github.com/fdasilvapa/cidade-invisivel)
