# Architecture & Responsibilities

O projeto segue uma arquitetura limpa focada em simplicidade e modularidade.

---

## Diagrama de Camadas

```mermaid
graph TD
    UI[Presentation (Widgets)] -->|Calls| Application[Application (Logic/State)]
    Application -->|Calls| Domain[Domain (Entities/Logic)]
    Application -->|Calls| Data[Data (Repositories/Sources)]
    Data -->|Implements| Domain
```

## 1. Presentation Layer (`lib/features/*/presentation`)

Responsável apenas por **renderizar** o estado e capturar input do usuário.

- **Widgets**: Devem ser "burros". Não contêm regras de negócio.
- **Navigation**: Use `GoRouter` (`context.go`, `context.push`).

## 2. Application Layer (`lib/features/*/application`)

A "cola" entre a UI e os Dados. Contém a lógica de aplicação e estado da tela.

- Gerencia o estado da feature.
- Expõe métodos para a UI.
- Trata exceções e converte dados.

## 3. Domain Layer (`lib/features/*/domain`)

O coração do negócio. DEVE ser independente de Flutter.

- **Entities**: Classes puras (ex: `Adventure`, `Creature`).
- **Failures**: Classes de erro customizadas.

## 4. Data Layer (`lib/features/*/data` ou `lib/core/database`)

Implementação técnica de acesso a dados.

- **HiveDatabase**: Singleton ou Classe que encapsula o acesso às boxes do Hive.
- **DTOs**: Se necessário, separe o modelo de banco do modelo de domínio.

---

## Regras de Dependência

- **Camada de Domínio** NÃO depende de ninguém.
- **Camada de Apresentação** depende de Aplicação e Domínio.
- **Camada de Dados** depende de Domínio.
