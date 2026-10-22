/// Frases fixas do aplicativo que podem ser gravadas com voz própria.
///
/// A [key] é o nome do arquivo (sem extensão) e precisa ser a mesma usada
/// em `clip:` no código das telas. O [text] precisa ser igual ao texto
/// usado no código (é o que a pessoa lê na hora de gravar).
class VoicePhrase {
  final String key;
  final String where;
  final String text;

  const VoicePhrase(this.key, this.where, this.text);
}

const List<VoicePhrase> kVoicePhrases = [
  VoicePhrase(
    'boas_vindas',
    'Tela de boas-vindas',
    'Bem-vindo ao AlertaMed. Aplicativo para organizar seus medicamentos. '
        'Toque em Começar para entrar, ou em Criar conta para se cadastrar.',
  ),
  VoicePhrase(
    'tela_pessoas',
    'Lista de pessoas',
    'Tela de pessoas. Toque em uma pessoa para ver os medicamentos, '
        'ou no botão Nova pessoa para cadastrar.',
  ),
  VoicePhrase(
    'tela_medicamentos',
    'Medicamentos (início)',
    'Tela de medicamentos.',
  ),
  VoicePhrase(
    'nenhum_medicamento',
    'Medicamentos (lista vazia)',
    'Nenhum medicamento cadastrado ainda.',
  ),
  VoicePhrase(
    'dica_medicamentos',
    'Medicamentos (final da narração)',
    'Toque em um medicamento para ouvir. '
        'O botão com o sinal de mais, no canto da tela, adiciona um novo.',
  ),
  VoicePhrase(
    'tela_novo_medicamento',
    'Novo medicamento',
    'Novo medicamento. Preencha o nome, a dosagem e os horários. '
        'Você também pode gravar o nome do remédio com a sua voz.',
  ),
  VoicePhrase(
    'tela_editar_medicamento',
    'Editar medicamento',
    'Editar medicamento.',
  ),
  VoicePhrase(
    'gravar_instrucao',
    'Antes de gravar o nome do remédio',
    'Diga o nome do remédio.',
  ),
  VoicePhrase(
    'gravacao_pronta',
    'Depois de gravar o nome do remédio',
    'Gravação pronta. Lembre-se de salvar o medicamento.',
  ),
  VoicePhrase(
    'medicamento_salvo',
    'Ao salvar um medicamento',
    'Medicamento salvo.',
  ),
  VoicePhrase(
    'medicamento_removido',
    'Ao remover um medicamento',
    'Medicamento removido.',
  ),
  VoicePhrase(
    'som_ativado',
    'Botão de som',
    'Som ativado.',
  ),
  VoicePhrase(
    'hora_do_medicamento',
    'Lembrete',
    'Hora do medicamento.',
  ),
  VoicePhrase(
    'tela_configuracoes_audio',
    'Configurações de áudio',
    'Configurações de áudio. Escolha a voz do aplicativo.',
  ),
  VoicePhrase(
    'tela_minha_voz',
    'Gravação da voz personalizada',
    'Minha voz. Escolha uma frase e grave com a sua voz.',
  ),
];
