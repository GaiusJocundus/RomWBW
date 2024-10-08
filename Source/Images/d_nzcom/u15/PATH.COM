�Z3ENV �*	�!  9"�!� "������C�w
SETPATH  Version 1.0
 :] �/�P:^ � �X�/�P����w
  SETPATH allows the user to display or modify the symbolic search path for
  transient programs.  Path elements may be expressed using drive-user (DU)
  or named-directory (DIR) form.  The character '$' may be used with the DU
  form to indicate the current drive or user (e.g., "B$" or "$2" or "$$").
  SETPATH sets or clears the program error flag.  Command syntax is:

    SETPATH                <-- Display Current Path
    SETPATH //             <-- Print This Help Screen
    SETPATH element-list   <-- Set New Path to element-list
    SETPATH [option element-list]....[option element-list]

  Where the option may be any of the following:

    /c          <-- Clear path and set to new element-list
    /p          <-- Prefix element-list to beginning of path
    /a          <-- Append element-list to end of path
    /d          <-- Delete element-list from path starting at beginning
    /r          <-- Remove element-list from path starting from the end
 �/p/P/a/A/d/D/c/C/r/R��2�"�|����|�w
 - Abort: No Path �>����w
 �͑*������-��¸�w
 - Abort: No Wheel >�~�����w
 - Abort: Illegal option -  !� �}>�~����w

  Input resulted in null path >�~���T�w
 - Abort: Too many paths for buffer !� �}>�~���w
 - Abort: to many paths  -  !� �}>�~��½�w
 - Abort: to many head paths  -  !� �}>�~�����w
 - Abort: to many tail paths  -  !� �}>�~����w
Bad Expression at  *��}>	�~> x��"�:�o& )�*)"�"�"�"�#"�##"�#"�*���*�� ����"�*�w2�2�2�2�2�*�"�*�"�*�"�*���y2��2�*��*��y*��R"���R
*������>c2��o	!<�N���*�~�/ʽ�2��"��o	:�2��2�*�6 *�"�:�� �c��p�!�d�}�rʭ�a�Rý�<
:�_:��2�!��ҋ*��_ � "��*��y*�~���ò:�_:��2�!����*��*��y�"�*�~���ò*��*�:�G�N̚�â~��w*��*�~���ò*���y�ʹ+�*� :�=O	:�G͏��� ����+~��w*��*�~���ò�O~��##~����*��:��O �":�� �c�	�I	*��*�:�O�~� �D	��@	#x��Y~#�&	�<
##�&	*��:��� O*���i	w#x��X	��b	*��R"�~��������:�!��*��<2�"�~�$��	�A�
G͠Ox��
#~�$��	�:��	� ��	���	�0�
�:�
#~ô	*��*�~�$��	�@#~#�$��	+��2��ͽ<Gy����~�:�
#"��"��o	*����
��*�p#q#"�*�~#��5
� �*
+"��o	*��*�~��R
#~#�C
����w
  Symbolic     DU        DIR
 *�~���"��
# �"*�~�$ʜ
�@#~�$ª
í
�>:��*�~�$��
x<�@#~�$��
y�>:*���~�$��
G#~�$��
O#"���[�>:�w
                                    ~�
����w
 � ~�0�P�
�PGy�؇؁؇؀�O#�4��~#� �R+��h�d!r~� �#�f�Noname ~��#~#�y~��#Æ��x�ڲ����ª+���������+��>���                                    �`~�<��#��~#�<��+�> ���`����ѯ�~����##��3#���F#N�ѯ=��� 	���0�S�:�Y�A�S�[�Y�G�x���G�=x��        ���r��~��o�#~+�##�=�� 	��r���ͮ �w�����*, ~����*" ~#fo�����*- ~����* ^#V#~�ѷ��*	 ^#V#~�ѷ���*( ~�����*) ~#fo~���"�  ����d�-
�-�0�K����� ��7�/�_y��A�{� y�0�K{�w#���x��q�����i#�X���������#�P��>�����}����� ~#����	ʻ���ʨ�
ʭ�ʭ�ʱÂ ÂÂy�ʂÂy�G>�G�O> ����Â��������O* .������������ �� � O�G�����}�o|�g��7�����a��{��_��*)}��'$. ��+                                                                                     