#    \  |         |
#  |\/ |   _  |  |  /   _
#  |   |  (   |    <    __/
# _|  _| \__,_| _|\_\ \___|
#                              
################################################################################
#                                     CONFIG                                   #
################################################################################

NAME		:= macmini_shell
CC			:= gcc
FLAGS		:= -Wall -Wextra -Werror

CLR_RMV		:= \033[0m
RED		    := \033[1;31m
GREEN		:= \033[1;32m
YELLOW		:= \033[1;33m
BLUE		:= \033[1;34m
CYAN 		:= \033[1;36m
RM			:= rm -rf

################################################################################
#                               PROGRAM'S INCLUDES                             #
################################################################################

LIBFT_DIR = libft/
LIBFT = libft.a
LIB := -lft -L./$(LIBFT_DIR)

UNAME 		= $(shell uname)

# Readline flags for Linux
ifeq ($(UNAME), Linux)
READLINE = -lreadline
INC_RL   = -I/usr/include/readline
FSAN	 = -fsanitize=address -g3
endif

# Readline flags for MacOS
ifeq ($(UNAME), Darwin)
RL_PREFIX	= $(shell brew --prefix readline)
READLINE 	= -lreadline -L$(RL_PREFIX)/lib
INC_RL		= -I$(RL_PREFIX)/include
endif


INC_DIR		= includes
INC			= -I./$(INC_DIR)
INC_LIBFT	= -I./$(LIBFT_DIR)$(INC_DIR)

################################################################################
#                                 PROGRAM'S SRCS                               #
################################################################################

SRC_DIR		:= ./src
SRC			:= $(addsuffix .c, \
					00_main \
					01_rc\
					02_prompt\
					03_expand\
					03a_expand_utils\
					04_lexer\
					04a_lexer_token_count\
					04b_lexer_char_count\
					04c_lexer_cmd_mod\
					05_parser\
					05a_parser_utils\
					06_execute\
					06a_exec_utils\
					06b_exec_path\
					07_pipe\
					08_redirection\
					08a_redir_utils\
					08b_redir_heredoc\
					09_builtin\
					09a_echo\
					09b_cd\
					09c_pwd\
					09d_export\
					09e_unset\
					09f_env\
					09g_history\
					09h_exit\
					09i_usage\
					09j_help\
					09k_setenv\
					09l_unsetenv\
					10_quote\
					10a_quote_utils\
					11_signal\
					11a_sigwait\
					12_free\
					13_minishell_utils\
					14_minishell_utils2\
					15_minishell_utils3\
				)

OBJ_DIR		:= ./obj
OBJ			:= $(SRC:%.c=$(OBJ_DIR)/%.o)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	@ $(CC) $(FLAGS) $(FSAN) $(INC) $(INC_LIBFT) $(INC_RL) -c $< -o $@
	@ printf "$(YELLOW)$<$(CLR_RMV)... "

################################################################################
#                                  Makefile  objs                              #
################################################################################

all: system-programs $(NAME)

run: all
	@ ./$(NAME)

$(NAME): $(LIBFT) $(OBJ)
	@ echo "\n$(GREEN)Compilation $(CLR_RMV)of $(BLUE) $(NAME) $(CLR_RMV)..."
	@ $(CC) $(FLAGS) $(FSAN) $(OBJ) $(LIBFT_DIR)$(LIBFT) $(LIB) $(READLINE) -o $(NAME)
	@ echo "$(GREEN)[Success] $(BLUE)$(NAME) $(CLR_RMV)created ✔️"

$(LIBFT):
	@ echo "$(GREEN)Making $(CYAN)Libft $(CLR_RMV) library..."
	@ $(MAKE) -C $(LIBFT_DIR)
	@ echo "$(GREEN)Generating $(BLUE)minishell $(CLR_RMV)object files..."


################################################################################
#                              SYSTEM PROGRAMS                                 #
################################################################################

SYS_NAME	:= system_programs
SYS_SRC_DIR	:= ./src/$(SYS_NAME)
BIN_DIR		:= ./bin

SYS_SOURCES	:= $(wildcard $(SYS_SRC_DIR)/*.c)
SYS_BINS	:= $(patsubst $(SYS_SRC_DIR)/%.c,$(BIN_DIR)/%,$(SYS_SOURCES))

sys-header:
	@ echo "$(GREEN)Generating $(CYAN)$(SYS_NAME) $(CLR_RMV)binaries..."

$(BIN_DIR)/%: $(SYS_SRC_DIR)/%.c
	@ mkdir -p $(BIN_DIR)
	@ $(CC) $(FLAGS) $(INC) -o $@ $<
	@ printf "$(YELLOW)$<$(CLR_RMV)... "

$(BIN_DIR)/logo.txt: $(SYS_SRC_DIR)/logo.txt
	@ mkdir -p $(BIN_DIR)
	@ cp $< $@

system-programs: sys-header $(SYS_BINS) $(BIN_DIR)/logo.txt
	@ echo "\n$(GREEN)[Success] $(BLUE)$(SYS_NAME) $(CLR_RMV)created ✔️"

################################################################################
#                                    TESTS                                     #
################################################################################

TESTS_DIR		:= ./tests
UNIT_DIR		:= $(TESTS_DIR)/unit
INTEGRATION_DIR	:= $(TESTS_DIR)/integration
UNITY_DIR		:= $(TESTS_DIR)/unity
UNIT_BIN_DIR	:= $(UNIT_DIR)/bin

UNIT_SOURCES	:= $(wildcard $(UNIT_DIR)/test_*.c)
UNIT_BINS		:= $(UNIT_SOURCES:$(UNIT_DIR)/%.c=$(UNIT_BIN_DIR)/%)

TEST_CFLAGS		:= -I./$(INC_DIR) -I./$(INC_DIR)/libs -I$(UNITY_DIR) -Wall -Wextra

$(UNIT_BIN_DIR)/test_%: $(UNIT_DIR)/test_%.c $(UNITY_DIR)/unity.c
	@mkdir -p $(UNIT_BIN_DIR)
	$(CC) $(TEST_CFLAGS) $^ $(EXTRA_SRC) -o $@

unit: $(UNIT_BINS)
	@echo "==> Running unit tests"
	@pass=0; fail=0; \
	for t in $(UNIT_BINS); do \
	  echo "--- $$t ---"; \
	  if $$t; then pass=$$((pass+1)); else fail=$$((fail+1)); fi; \
	done; \
	echo ""; \
	echo "Unit tests: $$pass passed, $$fail failed"; \
	test $$fail -eq 0

integration: $(NAME) $(SYS_BINS)
	@echo "==> Running integration tests"
	@pass=0; fail=0; \
	for s in $(INTEGRATION_DIR)/*.sh; do \
	  [ -f "$$s" ] || continue; \
	  echo "--- $$s ---"; \
	  if bash $$s; then pass=$$((pass+1)); else fail=$$((fail+1)); fi; \
	done; \
	echo ""; \
	echo "Integration tests: $$pass passed, $$fail failed"; \
	test $$fail -eq 0

test: unit integration

ai-unit-tests:
	@if [ -z "$(MODULE)" ]; then \
	  echo "Usage: make ai-unit-tests MODULE=name"; \
	  echo "  Looks for includes/libs/name.h"; \
	  echo "  Generates tests/unit/test_name.c"; \
	  exit 1; \
	fi
	@bash ./scripts/gen_unit_tests.sh $(MODULE)

################################################################################
#                                   CLEANUP                                    #
################################################################################

clean:
	@ $(RM) *.o */*.o */*/*.o
	@ $(RM) -r $(OBJ_DIR)
	@ $(RM) -r $(UNIT_BIN_DIR)
	@ echo "$(RED)Deleting $(BLUE)$(NAME) $(CLR_RMV)objs ✔️"

fclean: clean
	@ $(RM) $(NAME)
	@ $(RM) $(SYS_BINS)
	@ $(MAKE) fclean -C $(LIBFT_DIR)
	@ echo "$(RED)Deleting $(BLUE)$(NAME) $(CLR_RMV)binary ✔️"

re: fclean all

################################################################################
#                              PHONY && PRECIOUS                               #
################################################################################

.PHONY:		all clean fclean re run \
			system-programs sys-header unit integration test ai-unit-tests

.PRECIOUS:	$(NAME) $(OBJ)
