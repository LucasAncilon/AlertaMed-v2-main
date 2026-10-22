# Narração do aplicativo

## As três vozes

Em **Configurações de áudio** o usuário escolhe:

| Opção | O que faz |
|---|---|
| **Voz padrão do aplicativo** | Usa a voz sintética do celular. É a opção inicial. |
| **Voz dos desenvolvedores** | Usa as gravações da equipe, que ficam em `assets/audio/` (lista abaixo). |
| **Voz personalizável** | Abre a tela *Minha voz*, onde o usuário grava as frases com a própria voz. |

Em qualquer opção, se uma frase não tiver gravação, o app usa a voz do celular.
O **nome de cada remédio** gravado na tela de cadastro vale nas três vozes.

## Como a equipe grava a "voz dos desenvolvedores"

1. Escolha um lugar silencioso e grave todas as frases no mesmo celular, à mesma distância do microfone.
2. Leia cada frase **exatamente como está na tabela**.
3. Salve cada uma como arquivo de áudio (`.mp3`, `.m4a`, `.wav` ou `.ogg`) com o nome da coluna **Arquivo**. Exemplo: `boas_vindas.mp3`.
4. Coloque os arquivos em `assets/audio/`.
5. **Pare o app e rode de novo.** Áudios novos não aparecem com o hot reload.

Dica: grave tudo em um áudio só e corte depois no Audacity, com
*Arquivo > Exportar > Exportar múltiplos* (usando rótulos), que corta e nomeia os arquivos de uma vez.

## Frases

A mesma lista aparece na tela *Minha voz*. Ela é definida em `lib/services/voice_phrases.dart`.

| Arquivo (chave) | Onde toca | Frase |
|---|---|---|
| `boas_vindas` | Tela de boas-vindas | Bem-vindo ao AlertaMed. Aplicativo para organizar seus medicamentos. Toque em Começar para entrar, ou em Criar conta para se cadastrar. |
| `tela_pessoas` | Lista de pessoas | Tela de pessoas. Toque em uma pessoa para ver os medicamentos, ou no botão Nova pessoa para cadastrar. |
| `tela_medicamentos` | Medicamentos (início) | Tela de medicamentos. |
| `nenhum_medicamento` | Medicamentos (lista vazia) | Nenhum medicamento cadastrado ainda. |
| `dica_medicamentos` | Medicamentos (final da narração) | Toque em um medicamento para ouvir. O botão com o sinal de mais, no canto da tela, adiciona um novo. |
| `tela_novo_medicamento` | Novo medicamento | Novo medicamento. Preencha o nome, a dosagem e os horários. Você também pode gravar o nome do remédio com a sua voz. |
| `tela_editar_medicamento` | Editar medicamento | Editar medicamento. |
| `gravar_instrucao` | Antes de gravar o nome do remédio | Diga o nome do remédio. |
| `gravacao_pronta` | Depois de gravar o nome do remédio | Gravação pronta. Lembre-se de salvar o medicamento. |
| `medicamento_salvo` | Ao salvar um medicamento | Medicamento salvo. |
| `medicamento_removido` | Ao remover um medicamento | Medicamento removido. |
| `som_ativado` | Botão de som | Som ativado. |
| `hora_do_medicamento` | Lembrete | Hora do medicamento. |
| `tela_configuracoes_audio` | Configurações de áudio | Configurações de áudio. Escolha a voz do aplicativo. |
| `tela_minha_voz` | Gravação da voz personalizada | Minha voz. Escolha uma frase e grave com a sua voz. |

## O que nunca é gravado

Nome da pessoa, alergias, quantidade de medicamentos e dosagem mudam de pessoa para pessoa e sempre usam a voz do celular.

## Como adicionar uma frase nova

1. Em `lib/services/voice_phrases.dart`, acrescente um `VoicePhrase('chave', 'Onde toca', 'Texto')`.
2. Na tela, use exatamente a mesma chave e o mesmo texto:

```dart
return NarrateOnOpen(
  parts: const [VoicePart('Tela de login.', clip: 'tela_login')],
  child: Scaffold(...),
);
```

3. Grave `tela_login.mp3` para a voz dos desenvolvedores. Na voz personalizável, a frase já aparece sozinha na tela *Minha voz*.
