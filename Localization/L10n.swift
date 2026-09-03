import Foundation

enum L10nKey: String {
    case appName
    case tagline
    case newGame, settings, about
    case language, theme, darkMode, lightMode, systemMode
    case developedBy
    case yourTurn, opponentTurn, teamTurn
    case menu, rules, difficulty, easy, medium, hard
    case sound
    case victory, defeat, playAgain, backToMenu
    case undo, measureDistance
    case singles, doubles, triples
    case selectMode, selectModeSubtitle
    case teamA, teamB
    case coinToss, coinTossResult
    case endOfEnd, endOfEndSubtitle, continueButton
    case aboutDescription, aboutRulesTitle
    case rule1, rule2, rule3, rule4
    case website, github
    case dragToAim
    case ballsRemaining, cochonnet
    case start
    case shotMode, targetScoreLabel
    case terrain, terrainGrass, terrainHardDirt, terrainGravel
    case achievements, statistics
    case gamesPlayed, gamesWon, winRate, shotsTaken, pointsTaken, perfectShot
    case achievementFirstWin, achievementFirstWinDesc
    case achievementShutout, achievementShutoutDesc
    case achievementStreak5, achievementStreak5Desc
    case achievementSharpshooter, achievementSharpshooterDesc
    case achievementCarreau, achievementCarreauDesc
    case locked, unlocked, resetStats, resetStatsConfirm, cancel
    case ballColor, noAchievementsYet
}

enum L10n {
    private static let pt: [L10nKey: String] = [
        .appName: "Petanca",
        .tagline: "O clássico jogo francês, agora no teu iPhone",
        .newGame: "Novo Jogo",
        .settings: "Configurações",
        .about: "Sobre",
        .language: "Idioma",
        .theme: "Tema",
        .darkMode: "Escuro",
        .lightMode: "Claro",
        .systemMode: "Sistema",
        .developedBy: "Desenvolvido por",
        .yourTurn: "O teu turno",
        .opponentTurn: "Turno do adversário",
        .teamTurn: "Turno da equipa %@",
        .menu: "Menu",
        .rules: "Regras",
        .difficulty: "Dificuldade",
        .easy: "Fácil",
        .medium: "Médio",
        .hard: "Difícil",
        .sound: "Som",
        .victory: "Vitória!",
        .defeat: "Derrota",
        .playAgain: "Jogar Novamente",
        .backToMenu: "Voltar ao Menu",
        .undo: "Desfazer",
        .measureDistance: "Medir",
        .singles: "Simples",
        .doubles: "Duplas",
        .triples: "Triplas",
        .selectMode: "Escolhe o Modo",
        .selectModeSubtitle: "Seleciona o formato da partida",
        .teamA: "Equipa A",
        .teamB: "Equipa B",
        .coinToss: "A sortear quem começa...",
        .coinTossResult: "%@ começa!",
        .endOfEnd: "Fim da Mene",
        .endOfEndSubtitle: "%@ marcou %d ponto(s)",
        .continueButton: "Continuar",
        .aboutDescription: "Um jogo digital de Petanca com regras oficiais, física realista e uma experiência imersiva.",
        .aboutRulesTitle: "Regras Resumidas",
        .rule1: "Aproxima as tuas bolas do cochonnet o máximo possível.",
        .rule2: "A bola mais próxima do cochonnet comanda o jogo.",
        .rule3: "No fim de cada mene, marca-se 1 ponto por cada bola mais próxima do que a melhor bola adversária.",
        .rule4: "Vence quem chegar primeiro a 13 pontos.",
        .website: "ividi.dev",
        .github: "GitHub",
        .dragToAim: "Arrasta para apontar",
        .ballsRemaining: "Bolas restantes",
        .cochonnet: "Cochonnet",
        .start: "Começar",
        .shotMode: "TIRAR",
        .targetScoreLabel: "Pontuação Alvo",
        .terrain: "Terreno",
        .terrainGrass: "Relva",
        .terrainHardDirt: "Terra Batida",
        .terrainGravel: "Gravilha",
        .achievements: "Conquistas",
        .statistics: "Estatísticas",
        .gamesPlayed: "Jogos",
        .gamesWon: "Vitórias",
        .winRate: "% Vitórias",
        .shotsTaken: "Tiradas",
        .pointsTaken: "Apontadas",
        .perfectShot: "Carreau Perfeito",
        .achievementFirstWin: "Primeira Vitória",
        .achievementFirstWinDesc: "Ganha o teu primeiro jogo",
        .achievementShutout: "Vitória Impecável",
        .achievementShutoutDesc: "Vence por 13 a 0",
        .achievementStreak5: "Em Grande",
        .achievementStreak5Desc: "5 vitórias seguidas",
        .achievementSharpshooter: "Atirador Certeiro",
        .achievementSharpshooterDesc: "10 tiradas bem-sucedidas",
        .achievementCarreau: "Carreau!",
        .achievementCarreauDesc: "Uma bola tirada fica a menos de 3 cm do cochonnet",
        .locked: "Por desbloquear",
        .unlocked: "Desbloqueada",
        .resetStats: "Repor Estatísticas",
        .resetStatsConfirm: "Isto apaga todas as estatísticas e conquistas. Não pode ser desfeito.",
        .cancel: "Cancelar",
        .ballColor: "Cor das Bolas",
        .noAchievementsYet: "Ainda sem conquistas — joga uma partida!",
    ]

    private static let en: [L10nKey: String] = [
        .appName: "Petanca",
        .tagline: "The classic French game, now on your iPhone",
        .newGame: "New Game",
        .settings: "Settings",
        .about: "About",
        .language: "Language",
        .theme: "Theme",
        .darkMode: "Dark",
        .lightMode: "Light",
        .systemMode: "System",
        .developedBy: "Developed by",
        .yourTurn: "Your turn",
        .opponentTurn: "Opponent's turn",
        .teamTurn: "Team %@'s turn",
        .menu: "Menu",
        .rules: "Rules",
        .difficulty: "Difficulty",
        .easy: "Easy",
        .medium: "Medium",
        .hard: "Hard",
        .sound: "Sound",
        .victory: "Victory!",
        .defeat: "Defeat",
        .playAgain: "Play Again",
        .backToMenu: "Back to Menu",
        .undo: "Undo",
        .measureDistance: "Measure",
        .singles: "Singles",
        .doubles: "Doubles",
        .triples: "Triples",
        .selectMode: "Choose Mode",
        .selectModeSubtitle: "Select the match format",
        .teamA: "Team A",
        .teamB: "Team B",
        .coinToss: "Tossing to see who starts...",
        .coinTossResult: "%@ starts!",
        .endOfEnd: "End of Round",
        .endOfEndSubtitle: "%@ scored %d point(s)",
        .continueButton: "Continue",
        .aboutDescription: "A digital Petanca game with official rules, realistic physics and an immersive experience.",
        .aboutRulesTitle: "Rules Summary",
        .rule1: "Get your boules as close to the cochonnet as possible.",
        .rule2: "The closest boule to the cochonnet leads the point.",
        .rule3: "At the end of each round, score 1 point per boule closer than the opponent's best.",
        .rule4: "First team to reach 13 points wins.",
        .website: "ividi.dev",
        .github: "GitHub",
        .dragToAim: "Drag to aim",
        .ballsRemaining: "Balls remaining",
        .cochonnet: "Cochonnet",
        .start: "Start",
        .shotMode: "SHOT",
        .targetScoreLabel: "Target Score",
        .terrain: "Terrain",
        .terrainGrass: "Grass",
        .terrainHardDirt: "Hard Dirt",
        .terrainGravel: "Gravel",
        .achievements: "Achievements",
        .statistics: "Statistics",
        .gamesPlayed: "Games",
        .gamesWon: "Wins",
        .winRate: "Win Rate",
        .shotsTaken: "Shots",
        .pointsTaken: "Points",
        .perfectShot: "Perfect Carreau",
        .achievementFirstWin: "First Win",
        .achievementFirstWinDesc: "Win your first game",
        .achievementShutout: "Flawless Victory",
        .achievementShutoutDesc: "Win 13-0",
        .achievementStreak5: "On a Roll",
        .achievementStreak5Desc: "5 wins in a row",
        .achievementSharpshooter: "Sharpshooter",
        .achievementSharpshooterDesc: "10 successful shots",
        .achievementCarreau: "Carreau!",
        .achievementCarreauDesc: "A shot lands within 3cm of the cochonnet",
        .locked: "Locked",
        .unlocked: "Unlocked",
        .resetStats: "Reset Statistics",
        .resetStatsConfirm: "This clears all statistics and achievements. This cannot be undone.",
        .cancel: "Cancel",
        .ballColor: "Ball Color",
        .noAchievementsYet: "No achievements yet — play a match!",
    ]

    static func string(_ key: L10nKey, language: AppLanguage) -> String {
        let table = language == .portuguese ? pt : en
        return table[key] ?? key.rawValue
    }
}
