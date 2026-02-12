# Code Standards & Golden Rules

Estas regras são **OBRIGATÓRIAS** para todo código no projeto **GM Forge**.

## 1. Dart & Flutter Basics

- **Strong Typing**: Nunca use `var` ou `dynamic` a menos que estritamente necessário.
  ```dart
  // ✅ Good
  final String name = "Quest";
  final List<Adventure> adventures = [];
  
  // ❌ Bad
  var name = "Quest";
  var list = [];
  ```
- **Null Safety**: Garanta que campos nullable (`?`) sejam tratados corretamente. Use `required` para campos obrigatórios.
- **Lints**: Respeite os avisos do `flutter_lints`. Não ignore avisos sem justificativa forte.
- **No Comments**: O código deve ser auto-explicativo. **NÃO** adicione comentários a menos que seja algo extremamente complexo ou um hack temporário.

## 2. Widget Structure

- **Split Large Widgets**: Arquivos de UI não devem exceder **500 linhas**.
  - Se um `build` method for muito grande, extraia widgets privados (`_MySubWidget`) ou arquivos novos em `widgets/`.
  - **NÃO** use helper methods (`_buildHeader()`) para renderizar UI que tem estado ou dependências. Use Classes (`StatelessWidget`).
- **Const Constructors**: Use `const` sempre que possível para otimizar rebuilds.

## 3. State Management

- **Avoid Global Variables**: Gerencie o estado dentro do escopo apropriado.
- **Async Handling**: Trate sempre os estados de carregamento e erro na UI.
- **Immutability**: Prefira objetos imutáveis para garantir previsibilidade.

## 4. Database (Hive CE)

- **Adapters**: Sempre gere TypeAdapters para novas entidades (`@HiveType`, `@HiveField`).
- **Operations**: Todo acesso ao Hive deve ser encapsulado em classes dedicadas. Não acesse `Hive.box` diretamente na UI.
- **IDs**: Use `String` (UUID v4) para IDs de objetos.

## 5. Async & Await

- **Unawaited Futures**: Nunca dispare um `Future` sem `await` ou `unawaited` (se intencional).
- **UI Blocking**: Não faça operações pesadas no método `build`.
- **Error Handling**: Use `try/catch` para tratamentos de exceção.

## 6. Naming Conventions

- **Widgets**: `PascalCase` (ex: `AdventureCard`).
- **Files**: `snake_case.dart` (ex: `adventure_card.dart`).
- **Methods**: `camelCase` (ex: `saveAdventure`).

## 7. Documentation

- **Avoid**: Evite DartDoc (`///`) a menos que seja uma API pública complexa.
- **TODOs**: Use `// TODO: Descrição` apelas para trabalho futuro real.
