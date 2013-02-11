#include <iostream>
#include <vector>

template<typename T>
struct no_realloc_vector {
	std::vector<T *> array; //each pointer in vectors will point to a vector of Ts

	no_realloc_vector(int initial_size) {
		array.push_back(new T[initial_size]);
	}
	void insert(T element) {
		
	}
};

int main() {
	std::cout << "it works!" << std::endl;
}