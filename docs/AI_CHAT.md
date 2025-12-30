# AI Chat Feature

## Overview

The AI Chat feature provides an intelligent financial assistant that can analyze your spending patterns, track budgets, and provide insights about your transactions. The AI uses tool calling to fetch real-time data from your ledger database and can render charts to visualize financial data.

## Features

### 1. **Tool Calling Capabilities**
The AI assistant has access to the following tools:

- **Get Transactions**: Fetch transaction data with optional filters (date range, category)
- **Get Spending by Category**: Analyze spending breakdown by category with percentages
- **Get Spending by Month**: Track monthly spending trends over time
- **Get Account Balances**: View current balances across all accounts and net worth
- **Get Budget Status**: Check budget progress and remaining amounts

### 2. **Chart Rendering**
The AI can display three types of charts:

- **Pie Charts**: For category spending breakdowns
- **Bar Charts**: For monthly spending comparisons
- **Line Charts**: For spending trends over time

### 3. **Smart Responses**
The AI provides:
- Actionable insights based on spending patterns
- Budget tracking and alerts
- Saving recommendations
- Financial trend analysis

## Configuration

### API Setup

The AI service is designed to work with any OpenAI-compatible API endpoint. You can configure it through the app settings:

#### Method 1: Via Settings Screen (Recommended)

1. Open the app drawer and tap **Settings**
2. Scroll down to the **AI Assistant** section
3. Tap on **AI Assistant Configuration**
4. Enter your API endpoint and API key:
   - **API Endpoint**: e.g., `https://api.openai.com/v1/chat/completions`
   - **API Key**: Your API key (e.g., `sk-...`)
5. Tap **Save**

#### Method 2: Via AI Chat Screen

1. Open the AI chat screen
2. Tap the settings icon (⚙️) in the top right
3. Enter your API configuration
4. Tap **Save**

### Supported API Providers

The AI assistant works with any OpenAI-compatible API:

- **OpenAI**: `https://api.openai.com/v1/chat/completions`
  - Get API key from [OpenAI](https://platform.openai.com/api-keys)
  
- **OpenRouter**: `https://openrouter.ai/api/v1/chat/completions`
  - Get API key from [OpenRouter](https://openrouter.ai/)
  - Access to multiple AI models through one API
  
- **Local LLMs** (Ollama, LM Studio, etc.):
  - Ollama: `http://localhost:11434/v1/chat/completions`
  - LM Studio: `http://localhost:1234/v1/chat/completions`
  - No API key needed for local models
  
- **Other providers**: Any service with OpenAI-compatible API

### Fallback Mode

If no API key is configured, the AI will run in **mock mode** with predefined responses. This is useful for:
- Testing the UI without API costs
- Demonstrating the feature
- Offline usage

## Usage

### Accessing the AI Chat

1. Open the app drawer (hamburger menu)
2. Tap on **AI** (below "Reports & Statistics")
3. You'll see the AI chat screen with a welcome message

### Example Queries

Try asking the AI:

- "What's my spending by category this month?"
- "Show me my budget status"
- "How much have I spent compared to last month?"
- "What are my top spending categories?"
- "Can you give me tips to save money?"
- "What's my current net worth?"

### Clearing Chat History

Tap the trash icon in the top right corner to clear the conversation and start fresh.

## Architecture

### Key Components

1. **AiChatScreen** ([ai_chat_screen.dart](lib/screens/ai_chat_screen.dart))
   - Main chat interface
   - Message list with user and AI messages
   - Text input and send button
   - Loading indicators

2. **AiService** ([ai_service.dart](lib/services/ai_service.dart))
   - Handles communication with OpenAI API
   - Manages conversation context
   - Routes queries to appropriate tools
   - Provides fallback responses

3. **AiToolsService** ([ai_tools_service.dart](lib/services/ai_tools_service.dart))
   - Implements tool calling functions
   - Queries database through existing services
   - Formats data for AI consumption

4. **ChatMessageWidget** ([chat_message_widget.dart](lib/components/ai/chat_message_widget.dart))
   - Renders individual chat messages
   - Displays charts when available
   - Styled differently for user vs AI messages

5. **ChartRenderer** ([chart_renderer.dart](lib/components/ai/chart_renderer.dart))
   - Renders pie, bar, and line charts
   - Uses fl_chart package for visualizations
   - Themed to match app design

### Data Flow

```
User Input → AiService → AiToolsService → Database Services
                ↓
          OpenAI API
                ↓
         AI Response ← Chart Data (optional)
                ↓
        ChatMessageWidget
```

## Customization

### Adding New Tools

To add a new tool for the AI to use:

1. Add a method to `AiToolsService`:
   ```dart
   Future<Map<String, dynamic>> getNewData() async {
     // Fetch data from services
     return {
       'type': 'new_data_type',
       'data': yourData,
     };
   }
   ```

2. Update `_tryToolExecution` in `AiService` to route queries:
   ```dart
   else if (lowerQuery.contains('your keyword')) {
     return await _toolsService.getNewData();
   }
   ```

3. Update the system prompt in `sendMessage` to describe the new tool

### Changing AI Provider

The app supports any OpenAI-compatible API provider. Simply update your configuration through Settings:

1. Open **Settings** → **AI Assistant**
2. Tap **AI Assistant Configuration**
3. Update the endpoint and API key for your chosen provider
4. Tap **Save**

No code changes required!

### Styling Chat Messages

Customize the appearance in [chat_message_widget.dart](lib/components/ai/chat_message_widget.dart):
- Bubble colors
- Text styles
- Avatar icons
- Message spacing

### Chart Themes

Modify chart colors and styles in [chart_renderer.dart](lib/components/ai/chart_renderer.dart):
- Color palette
- Chart dimensions
- Label styles
- Animation effects

## Privacy & Security

- All data processing happens on-device except for the AI API calls
- Only the user's query and relevant data summaries are sent to the AI API
- No raw transaction details are sent unless specifically requested
- Consider implementing local AI models for complete privacy
- Store API keys securely (not hardcoded) in production apps

## Future Enhancements

Potential improvements:
- [ ] Local AI model integration (on-device processing)
- [ ] Voice input support
- [ ] Export chat conversations
- [ ] Scheduled insights and notifications
- [ ] Multi-currency support in AI responses
- [ ] Custom financial goals tracking
- [ ] Integration with financial news and market data
- [ ] Predictive spending analysis

## Troubleshooting

### AI Returns Generic Responses
- Check if API key is configured
- Verify internet connection
- Check API quota/billing status

### Charts Not Displaying
- Ensure data format matches expected structure
- Check console for chart rendering errors
- Verify fl_chart package is properly installed

### Tool Calls Failing
- Check if database services are properly initialized
- Verify data exists in the database
- Review error logs in console

## Dependencies

- `http`: For API communication
- `fl_chart`: For chart rendering (already included)
- `intl`: For date/currency formatting (already included)

No additional dependencies are required!

## Support

For issues or feature requests related to the AI chat feature, please check:
- Console logs for error messages
- Network requests in debug mode
- Database contents for data availability
