# AlertaMed 2.0

Aplicativo mobile desenvolvido em Flutter com foco em acessibilidade, autonomia e apoio à rotina medicamentosa.

A versão 2.0 dá continuidade ao MVP original do AlertaMed e marca o início de uma nova fase de desenvolvimento colaborativo, ampliando a solução com novos recursos de identificação, integração, segurança e acompanhamento autorizado.

---

## Sobre o projeto

O AlertaMed surgiu a partir da observação das dificuldades enfrentadas por pessoas que enxergam pouco e por usuários que precisam organizar sua rotina medicamentosa.

O projeto busca facilitar o gerenciamento de medicamentos e oferecer maior autonomia, segurança e acessibilidade no uso cotidiano.

Na versão 2.0, a proposta também passa a considerar de forma mais ampla a rede de apoio do usuário, permitindo evoluir o aplicativo para cenários de acompanhamento autorizado por familiares e cuidadores.

---

## Histórico

### Versão 1.0

A primeira versão do AlertaMed foi desenvolvida como um MVP individual, com foco na organização local da rotina medicamentosa e na construção de uma interface simples e acessível.

A versão 1.0 permanece disponível no repositório original:

[AlertaMed — versão 1.0](https://github.com/alcantarafabio/AlertaMed)

### Versão 2.0

A versão 2.0 parte da base existente e inicia uma nova etapa de desenvolvimento colaborativo, com expansão das funcionalidades, integrações e recursos de acessibilidade.

---

## Objetivos

- Facilitar a organização da rotina medicamentosa;
- Promover maior autonomia para pessoas que enxergam pouco;
- Melhorar a acessibilidade na identificação e consulta de medicamentos;
- Ampliar a segurança no acesso às informações do usuário;
- Permitir acompanhamento autorizado por familiares e cuidadores;
- Evoluir o projeto por meio da integração entre recursos locais, serviços e APIs.

---

## Público-alvo

O aplicativo é direcionado principalmente a:

- pessoas que enxergam pouco;
- usuários em tratamento contínuo;
- pessoas que utilizam múltiplos medicamentos;
- familiares;
- cuidadores.

---

## Base herdada da versão 1.0

A versão 2.0 utiliza como ponto de partida o MVP já desenvolvido, que inclui:

- Cadastro de pacientes;
- Cadastro e organização de medicamentos;
- Armazenamento local com SQLite;
- Interface desenvolvida em Flutter;
- Recursos voltados à acessibilidade;
- Destaque para informações importantes, como alergias;
- Organização da rotina de medicação;
- Estrutura multiplataforma do projeto.

---

## Escopo da versão 2.0

A nova fase prevê a evolução da base existente e o desenvolvimento dos seguintes recursos:

- Login, autenticação e controle de acesso;
- Evolução da camada de dados;
- Sincronização de informações;
- Integração com APIs;
- Termos de uso, permissões e consentimento;
- Acompanhamento autorizado por familiares e cuidadores;
- Uso da câmera para identificação de medicamentos;
- Reconhecimento de texto por OCR;
- Leitura de informações presentes em embalagens;
- Pesquisa e integração de recursos para consulta de bulas e informações de medicamentos;
- Recursos de voz e acessibilidade;
- Testes de software e documentação;
- Compatibilidade e integração entre sistemas.

> Os recursos desta seção fazem parte do escopo de desenvolvimento da versão 2.0 e podem estar em diferentes estágios de implementação, pesquisa ou integração.

---

## Tecnologias

### Base atual

- Flutter
- Dart
- SQLite (sqflite)

### Em evolução na versão 2.0

A arquitetura e as tecnologias adicionais serão definidas conforme o desenvolvimento das novas funcionalidades, incluindo banco de dados, autenticação, sincronização, OCR e integrações com APIs.

---

## Compatibilidade

A base do projeto possui suporte às plataformas:

- Android
- iOS

O projeto Flutter também mantém estrutura para outras plataformas, que poderão ser avaliadas conforme a evolução da versão 2.0.

---

## Estrutura atual do projeto

```text
lib/
├── database/
├── models/
├── screens/
├── theme/
└── widgets/

```text
lib/
├── database/
├── models/
├── screens/
├── theme/
└── widgets/
```

---

## Equipe

A versão 2.0 passa a ser desenvolvida de forma colaborativa.

- **Fábio** — Desenvolvimento Flutter, integração e compatibilidade de sistemas
- **Erick** — Login, autenticação e controle de acesso
- **Felipe** — Banco de dados, sincronização e APIs
- **Lucas** — Voz, acessibilidade e APIs
- **Paloma** — Termos, permissões, testes e documentação
- **Ruam** — Câmera, OCR, leitura e APIs