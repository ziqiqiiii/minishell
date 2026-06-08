#include "minishell.h"

static const t_help g_help[] = {
    {"echo",    "print args to stdout"},
    {"cd",      "change working directory"},
    {"pwd",     "print current working directory"},
    {"export",  "set environment variables"},
    {"unset",   "remove environment variables"},
    {"env",     "print all environment variables"},
    {"history", "print command history"},
    {"exit",    "exit the shell"},
    {"help",    "list all built-in commands"},
    {"usage",   "show detailed help for a built-in"},
    {NULL, NULL}
};

int	help(void)
{
    int i;

    printf("\nBuilt-in commands:\n");
    i = 0;
    while (g_help[i].name)
    {
        printf("  %-10s  %s\n", g_help[i].name, g_help[i].desc);
        i++;
    }
    printf("\nRun 'usage <builtin>' for detailed help.\n\n");
    return (EXIT_SUCCESS);
}
