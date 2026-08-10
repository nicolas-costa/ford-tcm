import {
    Callout,
    Card,
    CardBody,
    CardHeader,
    Divider,
    Grid,
    H1,
    H2,
    LineChart,
    BarChart,
    Spacer,
    Stack,
    Stat,
    Table,
    Text,
} from "cursor/canvas";

/**
 * AA stock vs v6.2 shift patches — plain language.
 * vel = TCM + 3. Source: docs 26 v6.2, 50; bins AA / AA_v6.2.
 */

export default function ShiftPatchesAAvsV62() {
    return (
        <Stack gap={24} style={{ padding: 24, maxWidth: 1040 }}>
            <Stack gap={6}>
                <H1>AA stock vs v6.2 — curvas dos patches</H1>
                <Text tone="secondary">
                    Artefato: AA_v6.2 (Block3 ck 0xD475). Velocímetro = TCM + 3. Cada
                    gráfico = um patch / um modo. Só 2 séries quando compara stock vs
                    patch.
                </Text>
            </Stack>

            <Grid columns={4} gap={12}>
                <Stat value="v5 base" label="P1–P5 inclusos" tone="info" />
                <Stat value="+T4→15" label="1→2 cedo @ leve" tone="success" />
                <Stat value="Y→0" label="modifiers GATE" tone="success" />
                <Stat value="T7 on" label="retomada (do v5)" tone="success" />
            </Grid>

            <Callout tone="info" title="Inventário v6.2 (em cima do AA)">
                Coast leve (piso 2ª 20→12) · Sair da 1ª no coast (23→15) · Coast
                brusco (segura 3ª 22→15) · Retomada (sai da 3ª mais alto) · Tip-in 1→2
                (17/23→15/18) · Modifiers GATE (+10/+5 → 0).
            </Callout>

            {/* -------- 1 RETOMADA -------- */}
            <Divider />
            <H2>1. Retomada — tip-in em 3ª (patch do v5, mantido)</H2>
            <Callout tone="warning" title="Significado">
                Em 3ª COM acelerador: se TCM estiver ABAIXO da curva → tenta 2ª; se
                ACIMA → fica em 3ª.
            </Callout>
            <LineChart
                categories={["6%", "12%", "20%", "29%", "51%", "83%"]}
                series={[
                    { name: "AA stock", data: [12, 14, 19, 25, 34, 56], tone: "neutral" },
                    { name: "v6.2", data: [12, 26, 27, 29, 34, 56], tone: "success" },
                ]}
                height={260}
                beginAtZero={false}
                yMin={10}
                yMax={60}
                referenceLines={[
                    { value: 15, label: "18 vel", tone: "warning" },
                    { value: 32, label: "35 vel", tone: "warning" },
                ]}
            />
            <Text tone="secondary" size="small">
                X = pedal %. Y = km/h TCM. v6.2 idêntico ao v5 nesta curva.
            </Text>

            {/* -------- 2 T4 -------- */}
            <Divider />
            <H2>2. Tip-in — quando sobe 1ª→2ª (T4)</H2>
            <Callout tone="warning" title="Significado">
                Em 1ª COM acelerador: sobe para 2ª se TCM ≥ valor da curva.
            </Callout>
            <LineChart
                categories={["0%", "12%", "20%", "25%", "39%", "59%"]}
                series={[
                    { name: "AA stock", data: [17, 17, 17, 23, 27, 32], tone: "neutral" },
                    { name: "v6.2", data: [15, 15, 17, 18, 27, 32], tone: "success" },
                ]}
                height={260}
                beginAtZero={false}
                yMin={12}
                yMax={36}
                referenceLines={[{ value: 15, label: "18 vel", tone: "warning" }]}
            />
            <Text tone="secondary" size="small">
                v6.2: rows 0–1 17→15 (~18 vel). Row @25% já vinha do v5: 23→18. Resto =
                AA.
            </Text>
            <Table
                headers={["Pedal", "AA (TCM)", "v6.2 (TCM)", "vel v6.2"]}
                rows={[
                    ["0–12%", "17", "15", "18"],
                    ["20%", "17", "17", "20"],
                    ["25%", "23", "18", "21"],
                    ["39%+", "27+", "27+", "30+"],
                ]}
                rowTone={["success", undefined, "success", undefined]}
            />

            {/* -------- 3 COAST LEVE -------- */}
            <Divider />
            <H2>3. Coast leve — piso da 2ª (pé fora suave)</H2>
            <Callout tone="warning" title="Significado">
                Em coast suave saindo da 3ª: 2ª se TCM ≥ curva; senão 1ª.
            </Callout>
            <LineChart
                categories={["0%", "20%", "39%", "60%", "85%", "93%"]}
                series={[
                    { name: "AA stock", data: [20, 20, 20, 20, 20, 31], tone: "neutral" },
                    { name: "v6.2", data: [12, 12, 12, 12, 12, 31], tone: "success" },
                ]}
                height={240}
                beginAtZero={false}
                yMin={8}
                yMax={40}
                referenceLines={[{ value: 15, label: "18 vel", tone: "warning" }]}
            />
            <Text tone="secondary" size="small">
                AA 20 TCM (23 vel) → v6.2 12 TCM (15 vel). Patch do v5, mantido.
            </Text>

            {/* -------- 3b SAIR DA 1ª (T10) -------- */}
            <Divider />
            <H2>3b. Coast — sair da 1ª (evita preso em 1ª)</H2>
            <Callout tone="warning" title="Significado">
                Já em 1ª no coast: sobe de volta para 2ª se TCM ≥ curva. Sem este
                patch, AA exige ~23 TCM (26 vel) — fica preso em 1ª depois de um 3→1 /
                2→1 cedo.
            </Callout>
            <LineChart
                categories={["0%", "12%", "20%", "39%", "59%", "80%"]}
                series={[
                    { name: "AA stock", data: [23, 23, 23, 23, 28, 39], tone: "neutral" },
                    { name: "v6.2", data: [15, 15, 15, 15, 28, 39], tone: "success" },
                ]}
                height={240}
                beginAtZero={false}
                yMin={10}
                yMax={45}
                referenceLines={[
                    { value: 15, label: "18 vel", tone: "warning" },
                    { value: 23, label: "AA 26 vel", tone: "neutral" },
                ]}
            />
            <Text tone="secondary" size="small">
                X = eixo da tabela. Y = km/h TCM. AA 23→ v6.2 15 TCM (26→18 vel) até
                ~39% do eixo; acima disso = stock.
            </Text>
            <Table
                headers={["Eixo", "AA: 1→2 se TCM ≥", "v6.2", "vel v6.2"]}
                rows={[
                    ["0–39%", "23", "15", "a partir de 18"],
                    ["59%+", "28+", "28+ (=AA)", "31+"],
                ]}
                rowTone={["success", undefined]}
            />

            {/* -------- 4 COAST BRUSCO -------- */}
            <Divider />
            <H2>4. Coast brusco — segura 3ª (pé fora forte)</H2>
            <Callout tone="warning" title="Significado">
                Freio motor forte: valor = piso para largar a 3ª. Abaixo → cai (sem
                faixa de 2ª neste modo). Acima → mantém 3ª.
            </Callout>
            <LineChart
                categories={["e0", "e1", "e2", "e3", "−10", "0", "20"]}
                series={[
                    { name: "AA stock", data: [22, 22, 22, 22, 22, 22, 22], tone: "neutral" },
                    { name: "v6.2", data: [15, 15, 15, 15, 15, 15, 15], tone: "success" },
                ]}
                height={220}
                beginAtZero={false}
                yMin={10}
                yMax={28}
                referenceLines={[
                    { value: 15, label: "18 vel", tone: "warning" },
                    { value: 22, label: "AA 25 vel", tone: "neutral" },
                ]}
            />
            <Text tone="secondary" size="small">
                Flat 22→15 TCM (25→18 vel). Prepara retomada ainda em 3ª.
            </Text>

            {/* -------- 5 MODIFIERS — NEW -------- */}
            <Divider />
            <H2>5. Novo no v6.2 — modifiers sob GATE (+10 / +5 → 0)</H2>
            <Text>
                Com GATE armado, o firmware faz: piso efetivo = base (ex. 12) + Y da
                tabela 1D. Stock Y = 10 ou 5 → S25/S27 viravam 22 ou 17 (bounce 2→1 /
                3→1 ~19–25 vel). v6.2 zera Y nas duas tabelas irmãs.
            </Text>
            <Callout tone="warning" title="Significado da curva Y">
                Y = km/h somados ao piso base quando GATE=1. Eixo X da tabela = sinal
                interno (valores negativos no stock). Patch: Y→0; eixos intactos; código
                do add intacto.
            </Callout>

            <Grid columns={2} gap={16}>
                <Stack gap={8}>
                    <Text weight="semibold">Modifier → piso da 2ª (S25)</Text>
                    <LineChart
                        categories={["−9", "−8", "−7", "−3", "−3b", "0"]}
                        series={[
                            { name: "AA / v5 Y", data: [10, 10, 10, 10, 5, 5], tone: "neutral" },
                            { name: "v6.2 Y", data: [0, 0, 0, 0, 0, 0], tone: "success" },
                        ]}
                        height={220}
                        yMin={0}
                        yMax={12}
                    />
                    <Text tone="secondary" size="small">
                        Dados @ 0x1856C8 (footer 0x185708). Doc 50.
                    </Text>
                </Stack>
                <Stack gap={8}>
                    <Text weight="semibold">modifier → saída da 3ª (S27)</Text>
                    <LineChart
                        categories={["−9", "−8", "−7", "−3", "−3b", "0"]}
                        series={[
                            { name: "AA / v5 Y", data: [10, 10, 10, 10, 5, 5], tone: "neutral" },
                            { name: "v6.2 Y", data: [0, 0, 0, 0, 0, 0], tone: "success" },
                        ]}
                        height={220}
                        yMin={0}
                        yMax={12}
                    />
                    <Text tone="secondary" size="small">
                        Espelho @ 0x185710 (footer 0x185750). Mesmo GATE.
                    </Text>
                </Stack>
            </Grid>

            <Text weight="semibold">Efeito com GATE=1 e base 12 TCM</Text>
            <BarChart
                categories={["Y=10 (stock)", "Y=5 (stock)", "Y=0 (v6.2)"]}
                series={[
                    {
                        name: "Piso efetivo TCM",
                        data: [22, 17, 12],
                        tone: "info",
                    },
                    {
                        name: "≈ velocímetro",
                        data: [25, 20, 15],
                        tone: "success",
                    },
                ]}
                height={240}
                yMax={30}
            />
            <Text tone="secondary" size="small">
                Live pré-patch: pacotes 24/22 e 19/17 com GATE=1. Alvo v6.2: FS≈12 e
                S25=12 (sumir 17/22).
            </Text>

            <Card>
                <CardHeader>GATE (doc 44) — só arma o add; não é o +5/+10</CardHeader>
                <CardBody>
                    <Text>
                        Flag 0x3FD48C é armada por condições (incl. float de frame 0x420).
                        Com GATE=1 o dispatcher soma Y. Zerar Y deixa o GATE inofensivo para
                        esse sintoma sem tocar no código.
                    </Text>
                </CardBody>
            </Card>

            {/* -------- checklist -------- */}
            <Divider />
            <H2>Checklist de pista (doc 26 v6.2)</H2>
            <Table
                headers={["#", "Cenário", "Esperado"]}
                rows={[
                    ["1", "Coast em 2ª", "Sem 2→1 ~19–22 vel; 2→1 só ~15 vel"],
                    ["2", "Coast saindo de 3ª ~20–25", "Preferir 3→2"],
                    ["3", "Tip-in leve", "1→2 ~18 vel"],
                    ["4", "Logger GATE=1", "FS≈12 e S25=12 (sem 19/17 nem 24/22)"],
                ]}
            />

            <Spacer />
            <Text tone="secondary" size="small">
                Fontes: 4f27e-docs/50, 26 §v6.2, 44. Bytes: AA.from_phf vs AA_v6.2.bin.
            </Text>
        </Stack>
    );
}
