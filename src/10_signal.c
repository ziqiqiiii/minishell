#include "minishell.h"

static void	signal_handler(int signum);
static void	signal_handler2(int signum);
static void	heredoc_signal(int signum);

/**
 * @brief Configures signal handlers based on the current shell mode.
 * 
 * CTRL-C -> SIGINT
 * CTRL-\ -> SIGQUIT
 * 
 * Mode 1: prompt mode — SIGINT reprints the prompt, SIGQUIT is ignored.
 * Mode 0: execution mode — SIGINT and SIGQUIT pass through to the child.
 * Mode 2: heredoc mode — SIGINT exits the heredoc child, SIGQUIT is ignored.
 *
 * @param mode Integer selecting the signal-handler set to install.
 */
void	signals(int mode)
{
	if (mode == 1)
	{
		signal(SIGINT, signal_handler);
		signal(SIGQUIT, signal_handler);
	}
	else if (mode == 0)
	{
		signal(SIGINT, signal_handler2);
		signal(SIGQUIT, signal_handler2);
	}
	else if (mode == 2)
	{
		signal(SIGINT, heredoc_signal);
		signal(SIGQUIT, SIG_IGN);
	}
	return ;
}

/**
 * @brief Handles SIGINT and SIGQUIT during normal prompt operation.
 *
 * On SIGINT, prints a newline and redraws the prompt. On SIGQUIT,
 * simply redraws the prompt without any output.
 *
 * @param signum The signal number received.
 */
static void	signal_handler(int signum)
{
	if (signum == SIGQUIT)
		return ;
	if (signum == SIGINT)
	{
		write(1, "\n", 1);
		rl_replace_line("", 0);
		rl_on_new_line();
		rl_redisplay();
		return ;
	}
}

/**
 * @brief Handles SIGINT and SIGQUIT during command execution (mode 0).
 *
 * On SIGINT, writes a newline. On SIGQUIT, writes "Quit: 3" to mimic
 * standard shell behaviour when a child is terminated by SIGQUIT.
 *
 * @param signum The signal number received.
 */
static void	signal_handler2(int signum)
{
	if (signum == SIGINT)
	{
		write(1, "\n", 1);
		return ;
	}
	if (signum == SIGQUIT)
	{
		write(1, "Quit: 3\n", 8);
	}
}

/**
 * @brief Handles SIGINT during heredoc input (mode 2).
 *
 * Immediately exits the heredoc child process so the parent can
 * detect cancellation via the child's exit status.
 *
 * @param signum The signal number received.
 */
static void	heredoc_signal(int signum)
{
	if (signum == SIGINT)
		exit(EXIT_FAILURE);
}
