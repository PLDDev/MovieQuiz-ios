import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    
    //MARK: Переменные
    
    // Переменная с индексом текущего вопроса, начальное значение 0
    private var currentQuestionIndex = 0
    
    // Переменная со счётчиком правильных ответов
    private var correctAnswers = 0
    
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticService?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
      
        questionFactory = QuestionFactory(delegate: self)
        
        questionFactory?.requestNextQuestion()
        
        alertPresenter = AlertPresenter()
        
        statisticService = StatisticServiceImplementation()
    }
    
    //MARK: - QuestionFactoryDelegate
    
    func didRecieveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
        
    //MARK: - Приватные методы
    
    // Метод конвертации, который принимает моковый вопрос и возвращает вью модель для экрана вопроса
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        // 1. Создаем константу questionStep и вызываем конструктор QuizStepViewModel
        let questionStep = QuizStepViewModel(
            
            // 2. Инициализируем картинку с помощью конструктора UIImage(named: ),
            // и если не найдется картинка с таким названием, то подставляем пустую
            image: UIImage(named: model.image) ?? UIImage(),
            
            // 3. Просто выбираем уже готовый вопрос из мокового вопроса
            question: model.text,
            
            // 4. Высчитываем номер вопроса с помощью переменной текущего вопроса
            // и массива со списком вопросов questions. С помощью интрополяции заполняем String
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        
        // 5. Метод конвертации должен вернуть объект структуры QuizStepViewModel. Созданный questionStep
        return questionStep
    }
    
    // Приватный метод вывода на экран вопроса, который принимает на вход вью модель вопроса и ничего не возвращает
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 15
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.imageView.layer.borderWidth = 0
        }
    }
    
    private func showNextQuestionOrResults() {
        
        if currentQuestionIndex == questionsAmount - 1 {
            
            guard let statisticService = statisticService else {
                return
            }
            
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            let bestGame = statisticService.bestGame
            let gamesCount = statisticService.gamesCount
            let date = bestGame.date.dateTimeString
            
            
            let text = """
                        Ваш результат: \(correctAnswers)/\(questionsAmount)
                        Количество сыгранных квизов: \(gamesCount)
                        Рекорд: \(bestGame.correct)/\(questionsAmount) (\(date))
                        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))
                        """
            let viewModel = AlertModel(
                title: "Этот раунд окончен",
                message: text,
                buttonText: "Сыграть еще раз",
                completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.currentQuestionIndex = 0
                    self.correctAnswers = 0
                    self.questionFactory?.requestNextQuestion()
                })
            alertPresenter?.presentAlert(from: self, quiz: viewModel)
        } else {
            currentQuestionIndex += 1

            questionFactory?.requestNextQuestion()
        }
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    
}

/*
 Mock-данные
 
 
 Картинка: The Godfather
 Настоящий рейтинг: 9,2
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: The Dark Knight
 Настоящий рейтинг: 9
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: Kill Bill
 Настоящий рейтинг: 8,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: The Avengers
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: Deadpool
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: The Green Knight
 Настоящий рейтинг: 6,6
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА


 Картинка: Old
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ


 Картинка: The Ice Age Adventures of Buck Wild
 Настоящий рейтинг: 4,3
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ


 Картинка: Tesla
 Настоящий рейтинг: 5,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ


 Картинка: Vivarium
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 */
