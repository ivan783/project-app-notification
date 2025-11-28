import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:push_app_new/domain/entities/product.dart';
import 'package:push_app_new/services/firebase_service.dart';

// ==================
// EVENTS
// ==================
abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {}

class AddProduct extends ProductsEvent {
  final Product product;
  const AddProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductsEvent {
  final String id;
  final Product product;
  const UpdateProduct(this.id, this.product);
  @override
  List<Object?> get props => [id, product];
}

class DeleteProduct extends ProductsEvent {
  final String id;
  const DeleteProduct(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchProducts extends ProductsEvent {
  final String query;
  const SearchProducts(this.query);
  @override
  List<Object?> get props => [query];
}

// Evento interno para actualizar la lista
class _ProductsLoaded extends ProductsEvent {
  final List<Product> products;
  const _ProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

// ==================
// STATES
// ==================
enum ProductsStatus { initial, loading, success, error }

class ProductsState extends Equatable {
  final List<Product> products;
  final ProductsStatus status;
  final String? errorMessage;

  const ProductsState({
    this.products = const [],
    this.status = ProductsStatus.initial,
    this.errorMessage,
  });

  ProductsState copyWith({
    List<Product>? products,
    ProductsStatus? status,
    String? errorMessage,
  }) {
    return ProductsState(
      products: products ?? this.products,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [products, status, errorMessage];
}

// ==================
// BLOC
// ==================
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final FirebaseService _firebaseService;
  StreamSubscription<List<Product>>? _productsSubscription;

  ProductsBloc(this._firebaseService) : super(const ProductsState()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<SearchProducts>(_onSearchProducts);
    on<_ProductsLoaded>(_onProductsLoaded);
  }

  // 🔹 Cargar productos en tiempo real
  void _onLoadProducts(LoadProducts event, Emitter<ProductsState> emit) {
    emit(state.copyWith(status: ProductsStatus.loading));

    _productsSubscription?.cancel();
    _productsSubscription = _firebaseService.getProductsStream().listen(
      (products) {
        add(_ProductsLoaded(products));
      },
      onError: (error) {
        emit(state.copyWith(
          status: ProductsStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  // 🔹 Agregar producto
  Future<void> _onAddProduct(AddProduct event, Emitter<ProductsState> emit) async {
    try {
      await _firebaseService.createProduct(event.product);
      emit(state.copyWith(status: ProductsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // 🔹 Actualizar producto
  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductsState> emit) async {
    try {
      await _firebaseService.updateProduct(event.id, event.product);
      emit(state.copyWith(status: ProductsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // 🔹 Eliminar producto
  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductsState> emit) async {
    try {
      await _firebaseService.deleteProduct(event.id);
      emit(state.copyWith(status: ProductsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // 🔹 Buscar productos
  void _onSearchProducts(SearchProducts event, Emitter<ProductsState> emit) {
    if (event.query.isEmpty) {
      add(LoadProducts());
      return;
    }

    _productsSubscription?.cancel();
    _productsSubscription = _firebaseService.searchProducts(event.query).listen(
      (products) {
        add(_ProductsLoaded(products));
      },
    );
  }

  // 🔹 Evento interno para actualizar estado con productos cargados
  void _onProductsLoaded(_ProductsLoaded event, Emitter<ProductsState> emit) {
    emit(state.copyWith(
      products: event.products,
      status: ProductsStatus.success,
    ));
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
