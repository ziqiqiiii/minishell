#include "minishell.h"

static void	get_rc_paths(t_root *sh, char *rc_path, char *home_path);
static void	run_rc(int fd, t_root *sh, char **envp);
static void	exec_rc_line(t_root *sh, char **envp, char *line);
static void	create_empty_rc(const char *path);

/**
 * @brief Locates and executes the .minishellrc startup configuration file.
 *
 * Searches in the shell binary's own directory first, then $HOME. Creates
 * an empty template rc file in the binary directory if neither location
 * has one. (reference: C-Shell-custom source/shell.c)
 *
 * @param sh The shell root structure.
 * @param envp Environment variables.
 * @see https://github.com/natalieagus/C-Shell-custom/tree/master
 */
void	source_rc(t_root *sh, char **envp)
{
	char	rc_path[PATH_MAX];
	char	home_path[PATH_MAX];
	int		fd;

	get_rc_paths(sh, rc_path, home_path);
	// printf("%s \n %s \n", rc_path, home_path);
	fd = -1;
	if (rc_path[0])
		fd = open(rc_path, O_RDONLY);
	if (fd == -1 && home_path[0])
		fd = open(home_path, O_RDONLY);
	if (fd != -1)
	{
		run_rc(fd, sh, envp);
		close(fd);
		return ;
	}
	if (rc_path[0])
		create_empty_rc(rc_path);
}

/**
 * @brief Builds the two candidate rc file paths.
 *
 * Resolves the running binary's directory via /proc/self/exe for the
 * project-local path, and reads $HOME for the fallback path. Either
 * string is left empty ("") if it cannot be resolved.
 *
 * @param rc_path Out buffer (PATH_MAX) for "<bindir>/.minishellrc".
 * @param home_path Out buffer (PATH_MAX) for "$HOME/.minishellrc".
 * @see https://github.com/natalieagus/C-Shell-custom/tree/master
 */
static void	get_rc_paths(t_root *sh, char *rc_path, char *home_path)
{
	const char	*home;

	rc_path[0] = '\0';
	home_path[0] = '\0';
	sh->current_dir = get_current_directory();
	snprintf(rc_path, PATH_MAX, "%s/.macminishellrc", sh->current_dir);
	home = getenv("HOME");
	if (home)
		snprintf(home_path, PATH_MAX, "%s/.macminishellrc", home);
}

/**
 * @brief Reads and executes commands from an open rc file descriptor.
 *
 * Skips blank lines and # comments. Each remaining line is run through
 * the normal shell pipeline (expand, lexer, parser, execute), so pipes,
 * redirections and builtins all work inside the rc file.
 *
 * @param fd Open file descriptor positioned at the start of the rc file.
 * @param sh The shell root structure.
 * @param envp Environment variables.
 * @see https://github.com/natalieagus/C-Shell-custom/tree/master
 */
static void	run_rc(int fd, t_root *sh, char **envp)
{
	char	*line;
	char	*s;
	size_t	len;

	line = get_next_line(fd);
	while (line)
	{
		len = ft_strlen(line);
		if (len > 0 && line[len - 1] == '\n')
			line[len - 1] = '\0';
		if (len > 0 && line[len - 2] == '\r')
			line[len - 2] = '\0';
		s = line;
		while (*s == ' ' || *s == '\t')
			s++;
		if (*s != '\0' && *s != '#')
			exec_rc_line(sh, envp, s);
		free(line);
		line = get_next_line(fd);
	}
}

/**
 * @brief Executes a single rc line through the shell pipeline.
 *
 * Mirrors the prompt loop's lexer/parser/exec flow, but does not add the
 * command to history since the user never typed it.
 *
 * @param sh The shell root structure.
 * @param envp Environment variables.
 * @param line The trimmed command line (not freed by this function).
 * @see https://github.com/natalieagus/C-Shell-custom/tree/master
 */
static void	exec_rc_line(t_root *sh, char **envp, char *line)
{
	char	*cmd;
	t_list	*cmd_lexer;
	t_tree	*head;

	cmd = expand(line, &sh->env_list);
	cmd_lexer = lexer(cmd);
	if (cmd_lexer == NULL)
	{
		free(cmd);
		return ;
	}
	head = parser(cmd_lexer, ft_lstsize(cmd_lexer), sh);
	ft_tcsetattr(STDIN_FILENO, TCSANOW, &sh->previous);
	recurse_bst(head, envp, sh);
	reset_data(sh, &cmd_lexer, &head);
	free(cmd);
}

/**
 * @brief Creates an empty .minishellrc file with a starter comment header.
 *
 * Uses O_EXCL so the file is only created if it does not already exist;
 * silently returns if the file is already present.
 *
 * @param path Absolute file path at which to create the rc file.
 * @see https://github.com/natalieagus/C-Shell-custom/tree/master
 */
static void	create_empty_rc(const char *path)
{
	int			fd;
	const char	*header;

	fd = ft_open(path, O_CREAT | O_EXCL | O_WRONLY, 0644);
	header = "# MacMini Shell start-up file\n"
		"# Add one command per line; blank lines and # comments"
		" are ignored.\n"
		"\n# Manifesting Mac Mini\n";
	write(fd, header, ft_strlen(header));
	close(fd);
}
