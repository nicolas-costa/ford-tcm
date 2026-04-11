## 01 — Reconstrução PHF → BIN (o que é e por que importou)

### O que é (o estado real)
O arquivo de entrada é PHF (Packed Hex File) “SILVEROAK”, com **marcadores de record** misturados ao payload. Se você fizer um “dump sequencial” (concatenar bytes), você **injeta marcadores no meio do código** e a engenharia reversa vira um teatro: disassembly quebra, “funções” aparecem com `.byte 0x3A 0x20`, decompilação falha, e você começa a nomear lixo.

### O que deveria ser
Um BIN plano em endereço absoluto (imagem ROM), onde:
- records são **parseados** (não copiados);
- payload é escrito nos offsets corretos;
- instruções PPC ficam alinhadas (word-aligned) e o IDA consegue criar funções de verdade.

### Correções aplicadas (fato)
- O pipeline PHF→BIN foi ajustado para **parsing real de records** (em vez de extração crua).
- Foi detectado um **misalignment global de 3 bytes** no BIN reconstruído; aplicar **shift global +3** fez o disassembly “cair no trilho”.

### Artefato final analisado (fato)
- **Arquivo**: `samples/SILVEROAK/5U75-14C337-AA.rebuilt.aligned.bin`
- **Tamanho**: `0x200000`
- **SHA256**: `1f76041d435540cdb96b9f819b775d06e4aaf89ce615ed8ac0089d757116cd53`

### Sinal de que a reconstrução está “boa” (evidência)
- A densidade de funções válidas no IDA aumentou drasticamente (“muuuit mais funções”).
- Segmento `ROM` ficou consistente como `r-x` e `make_func` passou a funcionar após correções de permissões/alinhamento.

### Anti-padrões (não repetir)
- **Converter PHF→BIN por concatenação**: isso fabrica falsos positivos de código e desperdiça semanas.
- **Confiar em decompilação sobre BIN desalinhado**: você vai “explicar” comportamento que não existe.


