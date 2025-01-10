require('dotenv').config();
const {Telegraf, Markup} = require('telegraf');

const BOT_TOKEN = process.env.BOT_TOKEN;
const CHAT_ID = process.env.CHAT_ID;

if (!BOT_TOKEN || !CHAT_ID) {
    console.error('Ошибка: TELEGRAM_BOT_TOKEN или TELEGRAM_CHAT_ID не заданы.');
    process.exit(1);
}

const bot = new Telegraf(BOT_TOKEN);

// Приветственное сообщение с клавиатурой (отправляется при запуске бота)
bot.start(async (ctx) => {
    // Проверяем, был ли уже отправлен приветственный текст
    console.log('Запуск бота. Пользователь:', ctx.from.username || ctx.from.first_name);

    try {
        // Новый способ создания клавиатуры
        await ctx.reply(
            'Добро пожаловать в SK Apps! Выберите тему вашего обращения:',
            Markup.keyboard([  // Создаем клавиатуру
                ['Жалоба', 'Предложение'],
                ['Сотрудничество', 'Общий вопрос'],
            ])
                .resize()
                .oneTime()
        );
    } catch (error) {
        console.error('Ошибка при отправке приветственного сообщения:', error);
    }
});

// Обработка нажатий на кнопки
bot.hears('Жалоба', (ctx) => {
    ctx.reply('Вы выбрали "Жалоба". Опишите вашу проблему, и мы обязательно свяжемся с вами.');
});

bot.hears('Предложение', (ctx) => {
    ctx.reply('Вы выбрали "Предложение". Напишите ваше предложение, и мы рассмотрим его.');
});

bot.hears('Сотрудничество', (ctx) => {
    ctx.reply('Вы выбрали "Сотрудничество". Расскажите, как мы можем с вами сотрудничать.');
});

bot.hears('Общий вопрос', (ctx) => {
    ctx.reply('Вы выбрали "Общий вопрос". Задайте ваш вопрос, и мы на него ответим.');
});

// Обработка всех остальных текстовых сообщений
bot.on('text', async (ctx) => {
    const message = ctx.message.text;
    const user = ctx.from;

    const feedbackMessage = `
    ✉️ Новое сообщение от пользователя:
    👤 Имя: ${user.first_name || ''} ${user.last_name || ''}
    🆔 Username: @${user.username || 'Не указан'}
    📝 Сообщение: ${message}
  `;

    // Отправляем сообщение администратору
    try {
        await bot.telegram.sendMessage(CHAT_ID, feedbackMessage);
        ctx.reply('Спасибо за ваше сообщение! Мы скоро свяжемся с вами.');
    } catch (error) {
        console.error('Ошибка отправки сообщения администратору:', error);
        ctx.reply('Произошла ошибка. Пожалуйста, попробуйте позже.');
    }
});

// Запуск бота
bot.launch()
    .then(() => console.log('Telegram-бот успешно запущен.'))
    .catch((error) => {
        console.error('Ошибка запуска бота:', error);
        process.exit(1);
    });

// Обработка завершения
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));
