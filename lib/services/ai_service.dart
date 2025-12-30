import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:ledger/models/ai_message.dart';
import 'package:ledger/services/ai_tools_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/services/user_preference_service.dart';

class AiService {
  final AiToolsService _toolsService = AiToolsService();
  static const int maxIterations = 3; // Strict limit: must complete in 3 turns

  Future<AiMessage> sendMessage(
    String userMessage,
    List<AiMessage> conversationHistory,
  ) async {
    LoggerService.i(
      'AI Service: Starting sendMessage for user input: "$userMessage"',
    );

    // Get API configuration from user preferences
    final apiEndpoint = await UserPreferenceService.getAiEndpoint();
    final apiKey = await UserPreferenceService.getAiApiKey();
    final modelName = await UserPreferenceService.getAiModel();
    final defaultCurrency = await UserPreferenceService.getDefaultCurrency();

    LoggerService.i(
      'AI Service: Config - endpoint: $apiEndpoint, model: $modelName, currency: $defaultCurrency',
    );

    // Get the appropriate currency symbol
    final currencySymbol = _getCurrencySymbol(defaultCurrency);

    // Build conversation context
    final List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        'content': _buildSystemPrompt(defaultCurrency, currencySymbol),
      },
      ...conversationHistory.map((m) => {'role': m.role, 'content': m.content}),
      {'role': 'user', 'content': userMessage},
    ];

    LoggerService.i(
      'AI Service: Built conversation with ${messages.length} messages',
    );

    try {
      // Check if API is configured
      if (apiEndpoint.isEmpty || apiKey.isEmpty) {
        LoggerService.w(
          'AI Service: API not configured - endpoint empty: ${apiEndpoint.isEmpty}, key empty: ${apiKey.isEmpty}',
        );
        return _buildConfigurationMessage();
      }

      // ========== EXACTLY 3 API CALLS ==========
      // API Call 1: Get initial information needed
      // API Call 2: Get additional information if needed
      // API Call 3: Use all data and return final response

      String? finalResponse;
      Map<String, dynamic>? chartInfo;

      // ========== API CALL 1: Get initial tools ==========
      LoggerService.i('AI Service: Starting API Call 1');
      final apiCall1Request = {
        'model': modelName,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
        'tools': _getToolDefinitions(),
        'tool_choice': 'auto',
      };

      final apiCall1Response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(apiCall1Request),
      );

      LoggerService.i(
        'AI Service: API Call 1 response status: ${apiCall1Response.statusCode}',
      );

      if (apiCall1Response.statusCode != 200) {
        LoggerService.e(
          'AI Service: API Call 1 failed with status ${apiCall1Response.statusCode}: ${apiCall1Response.body}',
        );
        throw Exception(
          'API Error: ${apiCall1Response.statusCode} - ${apiCall1Response.body}',
        );
      }

      final apiCall1Data = jsonDecode(apiCall1Response.body);
      LoggerService.i('AI Service: API Call 1 response parsed successfully');
      final apiCall1Message = _extractMessage(apiCall1Data);

      if (apiCall1Message == null) {
        LoggerService.e(
          'AI Service: API Call 1 - _extractMessage returned null. Response: ${apiCall1Response.body}',
        );
        throw Exception('Invalid API response: ${apiCall1Response.body}');
      }

      LoggerService.i(
        'AI Service: API Call 1 message extracted: ${apiCall1Message.containsKey('content') ? 'has content' : 'no content'}, tool_calls: ${apiCall1Message['tool_calls'] != null}',
      );

      messages.add(apiCall1Message);

      // Execute tools from API Call 1
      final toolCalls1 = apiCall1Message['tool_calls'];
      LoggerService.i(
        'AI Service: API Call 1 tool calls: ${toolCalls1 != null ? toolCalls1.length : 0}',
      );
      if (toolCalls1 != null && toolCalls1 is List && toolCalls1.isNotEmpty) {
        for (final toolCall in toolCalls1) {
          final toolName = toolCall['function']['name'];
          final toolArgs = jsonDecode(
            toolCall['function']['arguments'] ?? '{}',
          );
          final toolCallId = toolCall['id'];

          LoggerService.i(
            'AI Service: Executing tool: $toolName with args: $toolArgs',
          );
          final toolResult = await _executeTool(toolName, toolArgs);
          LoggerService.i(
            'AI Service: Tool $toolName result: ${toolResult.toString().substring(0, math.min(200, toolResult.toString().length))}...',
          );

          final toolMessage = <String, dynamic>{
            'role': 'tool',
            'tool_call_id': toolCallId,
            'content': jsonEncode(toolResult),
          };

          // Only include 'name' for OpenAI-compatible APIs, not Cohere
          if (!apiEndpoint.contains('cohere.com')) {
            toolMessage['name'] = toolName;
          }

          messages.add(toolMessage);
        }
      } else {
        // No tool calls from the model — infer tools heuristically based on the user query
        final inferred = _inferInitialTools(userMessage);
        if (inferred.isNotEmpty) {
          LoggerService.i(
            'AI Service: No tool calls from model, inferring tools: ${inferred.map((e) => e['name']).join(', ')}',
          );
          for (final inf in inferred) {
            final toolName = inf['name'] as String;
            final toolArgs = inf['arguments'] as Map<String, dynamic>;

            LoggerService.i(
              'AI Service: Executing inferred tool: $toolName with args: $toolArgs',
            );
            final toolResult = await _executeTool(toolName, toolArgs);
            LoggerService.i(
              'AI Service: Inferred Tool $toolName result: ${toolResult.toString().substring(0, math.min(200, toolResult.toString().length))}...',
            );

            final toolMessage = <String, dynamic>{
              'role': 'tool',
              'tool_call_id': DateTime.now().millisecondsSinceEpoch.toString(),
              'content': jsonEncode(toolResult),
            };

            if (!apiEndpoint.contains('cohere.com')) {
              toolMessage['name'] = toolName;
            }

            messages.add(toolMessage);
          }
        }
      }

      // ========== API CALL 2: Get additional tools if needed ==========
      LoggerService.i('AI Service: Starting API Call 2');
      final apiCall2Request = {
        'model': modelName,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
        'tools': _getToolDefinitions(),
        'tool_choice': 'auto',
      };

      final apiCall2Response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(apiCall2Request),
      );

      LoggerService.i(
        'AI Service: API Call 2 response status: ${apiCall2Response.statusCode}',
      );

      if (apiCall2Response.statusCode != 200) {
        LoggerService.e(
          'AI Service: API Call 2 failed with status ${apiCall2Response.statusCode}: ${apiCall2Response.body}',
        );
        throw Exception(
          'API Error: ${apiCall2Response.statusCode} - ${apiCall2Response.body}',
        );
      }

      final apiCall2Data = jsonDecode(apiCall2Response.body);
      LoggerService.i('AI Service: API Call 2 response parsed successfully');
      final apiCall2Message = _extractMessage(apiCall2Data);

      if (apiCall2Message == null) {
        LoggerService.e(
          'AI Service: API Call 2 - _extractMessage returned null. Response: ${apiCall2Response.body}',
        );
        throw Exception('Invalid API response: ${apiCall2Response.body}');
      }

      LoggerService.i(
        'AI Service: API Call 2 message extracted: ${apiCall2Message.containsKey('content') ? 'has content' : 'no content'}, tool_calls: ${apiCall2Message['tool_calls'] != null}',
      );

      messages.add(apiCall2Message);

      // Execute tools from API Call 2 (if any)
      final toolCalls2 = apiCall2Message['tool_calls'];
      LoggerService.i(
        'AI Service: API Call 2 tool calls: ${toolCalls2 != null ? toolCalls2.length : 0}',
      );
      if (toolCalls2 != null && toolCalls2 is List && toolCalls2.isNotEmpty) {
        for (final toolCall in toolCalls2) {
          final toolName = toolCall['function']['name'];
          final toolArgs = jsonDecode(
            toolCall['function']['arguments'] ?? '{}',
          );
          final toolCallId = toolCall['id'];

          LoggerService.i(
            'AI Service: Executing tool: $toolName with args: $toolArgs',
          );
          final toolResult = await _executeTool(toolName, toolArgs);
          LoggerService.i(
            'AI Service: Tool $toolName result: ${toolResult.toString().substring(0, math.min(200, toolResult.toString().length))}...',
          );

          final toolMessage = <String, dynamic>{
            'role': 'tool',
            'tool_call_id': toolCallId,
            'content': jsonEncode(toolResult),
          };

          // Only include 'name' for OpenAI-compatible APIs, not Cohere
          if (!apiEndpoint.contains('cohere.com')) {
            toolMessage['name'] = toolName;
          }

          messages.add(toolMessage);
        }
      }

      // ========== API CALL 3: Generate final response ==========
      LoggerService.i('AI Service: Starting API Call 3');
      final apiCall3Request = {
        'model': modelName,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
        // No tools provided - force text response only
      };

      final apiCall3Response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(apiCall3Request),
      );

      LoggerService.i(
        'AI Service: API Call 3 response status: ${apiCall3Response.statusCode}',
      );

      if (apiCall3Response.statusCode != 200) {
        LoggerService.e(
          'AI Service: API Call 3 failed with status ${apiCall3Response.statusCode}: ${apiCall3Response.body}',
        );
        throw Exception(
          'API Error: ${apiCall3Response.statusCode} - ${apiCall3Response.body}',
        );
      }

      final apiCall3Data = jsonDecode(apiCall3Response.body);
      LoggerService.i('AI Service: API Call 3 response parsed successfully');
      final apiCall3Message = _extractMessage(apiCall3Data);

      if (apiCall3Message == null) {
        LoggerService.e(
          'AI Service: API Call 3 - _extractMessage returned null. Response: ${apiCall3Response.body}',
        );
        throw Exception('Invalid API response: ${apiCall3Response.body}');
      }

      LoggerService.i(
        'AI Service: API Call 3 message extracted: ${apiCall3Message.containsKey('content') ? 'has content' : 'no content'}',
      );

      // Extract final response from API Call 3
      final rawContent = (apiCall3Message.containsKey('content'))
          ? apiCall3Message['content']
          : null;

      LoggerService.i(
        'AI Service: API Call 3 raw content: ${rawContent != null ? rawContent.toString().substring(0, math.min(100, rawContent.toString().length)) : 'null'}...',
      );

      if (rawContent != null && rawContent.toString().trim().isNotEmpty) {
        finalResponse = rawContent.toString();
        LoggerService.i(
          'AI Service: Final response from API Call 3: ${finalResponse.substring(0, math.min(100, finalResponse.length))}...',
        );
      }

      // Fallback 1: If API Call 3 has no content, check API Call 2
      if ((finalResponse == null || finalResponse.isEmpty) &&
          apiCall2Message.containsKey('content')) {
        final content2 = apiCall2Message['content'];
        if (content2 != null && content2.toString().trim().isNotEmpty) {
          finalResponse = content2.toString();
          LoggerService.i(
            'AI Service: Final response from API Call 2 fallback: ${finalResponse.substring(0, math.min(100, finalResponse.length))}...',
          );
        }
      }

      // Fallback 2: If still no content, check API Call 1
      if ((finalResponse == null || finalResponse.isEmpty) &&
          apiCall1Message.containsKey('content')) {
        final content1 = apiCall1Message['content'];
        if (content1 != null && content1.toString().trim().isNotEmpty) {
          finalResponse = content1.toString();
          LoggerService.i(
            'AI Service: Final response from API Call 1 fallback: ${finalResponse.substring(0, math.min(100, finalResponse.length))}...',
          );
        }
      }

      // Fallback 3: If we have tool results but no text, generate a summary
      if ((finalResponse == null || finalResponse.isEmpty) &&
          (toolCalls1 != null || toolCalls2 != null)) {
        finalResponse =
            'I\'ve retrieved your financial data. Please try asking your question again for a detailed analysis.';
        LoggerService.i('AI Service: Using fallback summary response');
      }

      LoggerService.i(
        'AI Service: Final response check - is null: ${finalResponse == null}, is empty: ${finalResponse?.isEmpty ?? true}',
      );

      if (finalResponse == null || finalResponse.isEmpty) {
        LoggerService.e(
          'AI Service: No final response generated after all fallbacks',
        );
        throw Exception(
          'AI did not generate a response. Please check your API configuration and try again.',
        );
      }

      chartInfo = _extractChartInfo(userMessage, null);

      return AiMessage(
        role: 'assistant',
        content: finalResponse,
        timestamp: DateTime.now(),
        chartData: chartInfo,
        chartType: chartInfo?['type'],
      );
    } catch (e) {
      LoggerService.e('AI Service: Exception in sendMessage: $e');
      return _buildErrorMessage(e);
    }
  }

  String _buildSystemPrompt(String currency, String symbol) {
    return '''You are a helpful financial assistant for Nexus Ledger, a personal finance app.

=== IDENTITY & CURRENCY ===
Today's date: ${DateTime.now().toString().split(' ')[0]}
User's currency: $currency ($symbol)

=== 🚨 EXACTLY 3 API CALLS - KNOW WHERE YOU ARE 🚨 ===
This conversation uses EXACTLY 3 API calls:
• **API CALL 1** (YOU ARE HERE): Get initial data - call the primary tools needed
• **API CALL 2**: After seeing initial results, call additional tools if needed OR say you're ready
• **API CALL 3**: Use all collected data to generate final response (NO tools available)

=== API CALL 1: GET INITIAL DATA ===
When user asks about financial data, IMMEDIATELY call the most relevant tools.
DO NOT write text - JUST CALL TOOLS.

Question Type → Initial Tools:
• Budgets → get_budget_status
• Spending → get_spending_by_category
• Transactions → get_recent_transactions
• Accounts → get_account_balances
• Overview → get_budget_status + get_account_balances

Examples:
User: "How are my budgets?"
YOU: [Call get_budget_status - NO text]

User: "Show me spending"
YOU: [Call get_spending_by_category - NO text]

=== API CALL 2: GET ADDITIONAL DATA (IF NEEDED) ===
After seeing results from API Call 1, decide:
• Need more context? Call additional tools
• Have enough data? Skip tools and prepare to respond

Examples:
- If you got budget data but need spending details → Call get_spending_by_category
- If you got account balances but need transactions → Call get_recent_transactions
- If you have everything needed → Don't call tools (move to API Call 3)

=== API CALL 3: GENERATE FINAL RESPONSE ===
Tools are NOT available here. Use the data you collected to write a complete answer.
• Be direct and conversational
• Use markdown formatting for better readability
• ALWAYS use formatted_amount fields from tool results
• Never manually format currency

IMPORTANT - Budget Formatting:
When displaying budget information, put each field on its OWN LINE like this:

**Budget Name:** Monthly Expenses  
**Budget Amount:** ₹30,000.00  
**Spent:** ₹20,000.00  
**Remaining:** ₹10,000.00  
**Percentage Spent:** 66.67%

DO NOT write: "Budget Amount: ₹30,000.00 Spent: ₹20,000.00"
DO write each field on a separate line with double spaces at the end for line breaks

=== CRITICAL: NO HALLUCINATION ===
• ONLY use data from tool results
• If data is empty, say so honestly
• NEVER fabricate numbers

=== FORBIDDEN IN API CALL 1 & 2 ===
❌ "I need to fetch that data first"
❌ "Let me get that information"
❌ Any text explanation before calling tools
✅ Just call the tools immediately

Remember: 
- API Call 1: Get primary data (call tools)
- API Call 2: Get additional data if needed (call tools OR skip)
- API Call 3: Generate response (NO tools, just write answer)''';
  }

  AiMessage _buildConfigurationMessage() {
    return AiMessage(
      role: 'assistant',
      content: '''⚠️ AI API not configured

To chat with a real AI assistant, please configure your API:

1. Go to Settings → AI Assistant
2. Tap "AI Assistant Configuration"
3. Enter your API endpoint and key

Supported providers:
• OpenAI (api.openai.com)
• OpenRouter (openrouter.ai)
• Local LLMs (Ollama, LM Studio)

Once configured, I'll be able to provide personalized financial insights!''',
      timestamp: DateTime.now(),
    );
  }

  AiMessage _buildErrorMessage(dynamic error) {
    return AiMessage(
      role: 'assistant',
      content:
          '''❌ Error communicating with AI

${error.toString()}

Please check:
• Your API endpoint and key are correct in Settings
• You have internet connection
• Your API key is valid and has credits

Go to Settings → AI Assistant to update your configuration.''',
      timestamp: DateTime.now(),
    );
  }

  /// Define all available tools in OpenAI function calling format
  List<Map<String, dynamic>> _getToolDefinitions() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'get_transactions',
          'description':
              'Get transaction history with optional filters for date range and category',
          'parameters': {
            'type': 'object',
            'properties': {
              'startDate': {
                'type': 'string',
                'description': 'Start date in ISO 8601 format (YYYY-MM-DD)',
              },
              'endDate': {
                'type': 'string',
                'description': 'End date in ISO 8601 format (YYYY-MM-DD)',
              },
              'categoryId': {
                'type': 'string',
                'description': 'Filter by specific category ID',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_spending_by_category',
          'description':
              'Get spending breakdown by category with amounts and percentages',
          'parameters': {
            'type': 'object',
            'properties': {
              'startDate': {
                'type': 'string',
                'description': 'Start date in ISO 8601 format (YYYY-MM-DD)',
              },
              'endDate': {
                'type': 'string',
                'description': 'End date in ISO 8601 format (YYYY-MM-DD)',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_spending_by_month',
          'description': 'Get monthly spending trends over multiple months',
          'parameters': {
            'type': 'object',
            'properties': {
              'monthsBack': {
                'type': 'integer',
                'description': 'Number of months to look back (default: 6)',
                'default': 6,
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_account_balances',
          'description':
              'Get all account balances and total net worth in user currency',
          'parameters': {'type': 'object', 'properties': {}},
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_budget_status',
          'description':
              'Get budget progress with spent, remaining, and percentage',
          'parameters': {'type': 'object', 'properties': {}},
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'calculate',
          'description': 'Perform mathematical calculations',
          'parameters': {
            'type': 'object',
            'properties': {
              'expression': {
                'type': 'string',
                'description':
                    'Mathematical expression to evaluate (e.g., "500 + 250 * 0.18")',
              },
            },
            'required': ['expression'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_statistics',
          'description':
              'Calculate statistical metrics (mean, median, min, max, stdDev) for transaction amounts',
          'parameters': {
            'type': 'object',
            'properties': {
              'startDate': {
                'type': 'string',
                'description': 'Start date for transaction filter',
              },
              'endDate': {
                'type': 'string',
                'description': 'End date for transaction filter',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_recent_transactions',
          'description': 'Get the most recent N transactions',
          'parameters': {
            'type': 'object',
            'properties': {
              'limit': {
                'type': 'integer',
                'description':
                    'Number of recent transactions to fetch (default: 10)',
                'default': 10,
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_top_expenses',
          'description': 'Get the largest expense transactions',
          'parameters': {
            'type': 'object',
            'properties': {
              'limit': {
                'type': 'integer',
                'description': 'Number of top expenses to return (default: 5)',
                'default': 5,
              },
              'startDate': {
                'type': 'string',
                'description': 'Start date for filtering',
              },
              'endDate': {
                'type': 'string',
                'description': 'End date for filtering',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'compare_periods',
          'description': 'Compare spending between two time periods',
          'parameters': {
            'type': 'object',
            'properties': {
              'period': {
                'type': 'string',
                'description':
                    'Period to compare: "month" for this month vs last month, "week" for this week vs last week',
                'enum': ['month', 'week'],
              },
            },
            'required': ['period'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'search_transactions',
          'description':
              'Search transactions by keyword in title or description',
          'parameters': {
            'type': 'object',
            'properties': {
              'keyword': {
                'type': 'string',
                'description': 'Keyword to search for in transaction titles',
              },
            },
            'required': ['keyword'],
          },
        },
      },
    ];
  }

  /// Execute a tool based on its name and arguments
  Future<Map<String, dynamic>> _executeTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    try {
      switch (toolName) {
        case 'get_transactions':
          return await _toolsService.getTransactions(
            startDate: args['startDate'] != null
                ? DateTime.parse(args['startDate'])
                : null,
            endDate: args['endDate'] != null
                ? DateTime.parse(args['endDate'])
                : null,
            categoryId: args['categoryId'],
          );

        case 'get_spending_by_category':
          return await _toolsService.getSpendingByCategory(
            startDate: args['startDate'] != null
                ? DateTime.parse(args['startDate'])
                : null,
            endDate: args['endDate'] != null
                ? DateTime.parse(args['endDate'])
                : null,
          );

        case 'get_spending_by_month':
          return await _toolsService.getSpendingByMonth(
            monthsBack: args['monthsBack'] ?? 6,
          );

        case 'get_account_balances':
          return await _toolsService.getAccountBalances();

        case 'get_budget_status':
          return await _toolsService.getBudgetStatus();

        case 'calculate':
          return await _toolsService.calculate(args['expression'] ?? '0');

        case 'get_statistics':
          return await _toolsService.getStatisticsFromTransactions(
            startDate: args['startDate'] != null
                ? DateTime.parse(args['startDate'])
                : null,
            endDate: args['endDate'] != null
                ? DateTime.parse(args['endDate'])
                : null,
          );

        case 'get_recent_transactions':
          return await _toolsService.getRecentTransactions(
            limit: args['limit'] ?? 10,
          );

        case 'get_top_expenses':
          return await _toolsService.getTopExpenses(
            limit: args['limit'] ?? 5,
            startDate: args['startDate'] != null
                ? DateTime.parse(args['startDate'])
                : null,
            endDate: args['endDate'] != null
                ? DateTime.parse(args['endDate'])
                : null,
          );

        case 'compare_periods':
          return await _toolsService.comparePeriods(args['period'] ?? 'month');

        case 'search_transactions':
          return await _toolsService.searchTransactions(args['keyword'] ?? '');

        default:
          return {'error': 'Unknown tool: $toolName'};
      }
    } catch (e) {
      return {'error': 'Tool execution failed: ${e.toString()}'};
    }
  }

  Map<String, dynamic>? _extractChartInfo(
    String query,
    Map<String, dynamic>? toolResult,
  ) {
    // Chart extraction logic - to be enhanced based on conversation context
    // For now, we'll keep it simple
    return null;
  }

  /// Infer which tools are needed for a user message when the model doesn't request tools
  List<Map<String, dynamic>> _inferInitialTools(String userMessage) {
    final text = userMessage.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Spending / suggestions about reducing spending
    if (text.contains('spend') ||
        text.contains('spending') ||
        text.contains('reduce') ||
        text.contains('stop spending') ||
        text.contains('suggest') ||
        text.contains('what should i') ||
        text.contains('advice')) {
      results.add({'name': 'get_spending_by_category', 'arguments': {}});
      results.add({
        'name': 'get_top_expenses',
        'arguments': {'limit': 5},
      });
    }

    // Transactions / recent transactions
    if (text.contains('transaction') ||
        text.contains('transactions') ||
        text.contains('recent transactions')) {
      results.add({
        'name': 'get_recent_transactions',
        'arguments': {'limit': 10},
      });
    }

    // Budgets
    if (text.contains('budget') || text.contains('budgets')) {
      results.add({'name': 'get_budget_status', 'arguments': {}});
    }

    // Accounts / balances
    if (text.contains('balance') ||
        text.contains('balances') ||
        text.contains('account')) {
      results.add({'name': 'get_account_balances', 'arguments': {}});
    }

    // Deduplicate by name, preserving first occurrence
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final r in results) {
      final n = r['name'] as String;
      if (!seen.contains(n)) {
        deduped.add(r);
        seen.add(n);
      }
    }

    return deduped;
  }

  /// Normalize message content into a displayable markdown string
  String _normalizeMessageContent(dynamic input) {
    LoggerService.i(
      'AI Service: _normalizeMessageContent input type: ${input.runtimeType}, value: ${input.toString().substring(0, math.min(200, input.toString().length))}...',
    );
    if (input == null) return '';

    // If input is a map that wraps content, extract it recursively
    if (input is Map && input.containsKey('content')) {
      LoggerService.i(
        'AI Service: _normalizeMessageContent - extracting content from map',
      );
      return _normalizeMessageContent(input['content']);
    }

    // If input is already a string, return it
    if (input is String) {
      // Clean up any accidental stringified objects
      if (input.startsWith('{role:') || input.startsWith('[{type:')) {
        LoggerService.i(
          'AI Service: _normalizeMessageContent - string starts with filtered pattern, returning empty',
        );
        return '';
      }
      LoggerService.i(
        'AI Service: _normalizeMessageContent - returning string content',
      );
      return input;
    }

    // If input is a list of blocks (common for some APIs), extract text blocks
    if (input is List) {
      final texts = <String>[];
      for (final block in input) {
        if (block is Map) {
          // Handle {type: 'text', text: 'actual content'} format
          if (block.containsKey('type') &&
              block['type'] == 'text' &&
              block.containsKey('text')) {
            final textValue = block['text'];
            if (textValue is String) {
              texts.add(textValue);
            } else {
              texts.add(textValue.toString());
            }
          } else if (block.containsKey('text')) {
            final textValue = block['text'];
            if (textValue is String) {
              texts.add(textValue);
            } else {
              texts.add(textValue.toString());
            }
          }
        } else if (block is String) {
          texts.add(block);
        }
      }
      return texts.join('\n');
    }

    // If input is a map with a 'text' field
    if (input is Map && input.containsKey('text')) {
      final textValue = input['text'];
      if (textValue is String) {
        return textValue;
      }
      return textValue.toString();
    }

    // If input is a complex map (like a full message object), don't stringify it
    // This prevents showing raw message objects with tool_calls, role, etc.
    if (input is Map) {
      return '';
    }

    // Fallback to a safe string representation (only for primitives)
    return input.toString();
  }

  /// Get the currency symbol for a given currency code
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      default:
        return currencyCode;
    }
  }

  /// Extract message from API response (handles different formats)
  Map<String, dynamic>? _extractMessage(Map<String, dynamic> data) {
    Map<String, dynamic>? message;
    Map<String, dynamic>? choice;

    if (data['choices'] != null &&
        data['choices'] is List &&
        data['choices'].isNotEmpty) {
      choice = data['choices'][0] as Map<String, dynamic>?;
      message = choice?['message'] as Map<String, dynamic>?;
    } else if (data['message'] != null) {
      // Some APIs return message directly
      final msg = data['message'];
      if (msg is String) {
        // Try to parse if it's a JSON string
        try {
          final parsed = jsonDecode(msg);
          if (parsed is Map) {
            message = parsed as Map<String, dynamic>;
          }
        } catch (e) {
          // Not JSON, treat as plain text
          message = {'role': 'assistant', 'content': msg};
        }
      } else if (msg is Map) {
        message = msg as Map<String, dynamic>;
      } else {
        message = {'role': 'assistant', 'content': msg.toString()};
      }
    } else if (data['content'] != null) {
      // Alternative format
      message = {'role': 'assistant', 'content': data['content'].toString()};
    }

    if (message != null && message.containsKey('content')) {
      // Normalize content to string
      message['content'] = _normalizeMessageContent(message['content']);
    }

    // === New: detect tool/function calls returned in different formats ===
    // 1) OpenAI-style `function_call` inside `message`
    // 2) Provider-style `tool_calls` attached to choice
    // 3) Plain-text hints like "Call get_recent_transactions"
    final detectedCalls = <Map<String, dynamic>>[];

    // Case A: OpenAI style function_call
    try {
      final func = (message != null && message['function_call'] != null)
          ? message['function_call']
          : (choice != null &&
                choice['message'] != null &&
                (choice['message'] as Map<String, dynamic>)['function_call'] !=
                    null)
          ? (choice['message'] as Map<String, dynamic>)['function_call']
          : null;
      if (func != null && func is Map && func['name'] != null) {
        final argsRaw = func['arguments'] ?? func['args'] ?? '{}';
        String argsStr = '{}';
        if (argsRaw is String) argsStr = argsRaw;
        if (argsRaw is Map) argsStr = jsonEncode(argsRaw);

        detectedCalls.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'function': {'name': func['name'].toString(), 'arguments': argsStr},
        });

        // Clear content so we don't show function_call text to users
        message?['content'] = '';
      }
    } catch (_) {}

    // Case B: Provider-specific tool_calls attached to the choice
    try {
      final tc = (choice != null && choice['tool_calls'] != null)
          ? choice['tool_calls']
          : (choice != null && choice['tool_call'] != null)
          ? choice['tool_call']
          : null;
      if (tc != null) {
        if (tc is List) {
          for (final call in tc) {
            if (call is Map && call['function'] != null) {
              detectedCalls.add({
                'id':
                    call['id']?.toString() ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                'function': call['function'],
              });
            }
          }
        } else if (tc is Map && tc['function'] != null) {
          detectedCalls.add({
            'id':
                tc['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'function': tc['function'],
          });
        }

        // Clear content to avoid showing raw tool call artifacts
        message?['content'] = '';
      }
    } catch (_) {}

    // Case C: Plain text like "Call get_recent_transactions" or "[Call get_recent_transactions]"
    try {
      if (message != null && message['content'] is String) {
        final contentStr = message['content'] as String;
        final regex = RegExp(
          r"\bCall\s+([a-zA-Z0-9_]+)\b",
          caseSensitive: false,
        );
        final matches = regex.allMatches(contentStr);
        for (final m in matches) {
          final name = m.group(1);
          if (name != null && name.trim().isNotEmpty) {
            detectedCalls.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'function': {'name': name.trim(), 'arguments': '{}'},
            });
          }
        }

        if (matches.isNotEmpty) {
          // Remove the textual call annotations from content before displaying
          var newContent = contentStr.replaceAll(regex, '');
          // Also remove leftover brackets/parentheses and stray punctuation
          newContent = newContent
              .replaceAll(RegExp(r'[\[\]\(\)\:\,]'), '')
              .trim();
          message['content'] = newContent;
          if ((message['content'] as String).isEmpty) {
            message['content'] = '';
          }
        }
      }
    } catch (_) {}

    if (detectedCalls.isNotEmpty) {
      message ??= {'role': 'assistant'};
      message['tool_calls'] = detectedCalls;
    }

    return message;
  }
}
